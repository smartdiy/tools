package executor.v6;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;
import java.util.concurrent.atomic.LongAdder;

public class ShardedLockFreeMultiKeyExecutor {

    public static final String VERSION = "6.2-MURMUR-FASTPATH-ISOLATED";

    // =============================
    // Murmur3 32-bit
    // =============================
    static final class Murmur3 {
        static int hash32(byte[] data, int seed) {
            final int c1 = 0xcc9e2d51;
            final int c2 = 0x1b873593;

            int h1 = seed;
            ByteBuffer buffer = ByteBuffer.wrap(data).order(ByteOrder.LITTLE_ENDIAN);

            while (buffer.remaining() >= 4) {
                int k1 = buffer.getInt();
                k1 *= c1;
                k1 = Integer.rotateLeft(k1, 15);
                k1 *= c2;

                h1 ^= k1;
                h1 = Integer.rotateLeft(h1, 13);
                h1 = h1 * 5 + 0xe6546b64;
            }

            int k1 = 0;
            int remaining = buffer.remaining();
            for (int i = 0; i < remaining; i++) {
                k1 ^= (buffer.get() & 0xff) << (i * 8);
            }

            if (remaining > 0) {
                k1 *= c1;
                k1 = Integer.rotateLeft(k1, 15);
                k1 *= c2;
                h1 ^= k1;
            }

            h1 ^= data.length;
            h1 ^= (h1 >>> 16);
            h1 *= 0x85ebca6b;
            h1 ^= (h1 >>> 13);
            h1 *= 0xc2b2ae35;
            h1 ^= (h1 >>> 16);

            return h1;
        }
    }

    static final class Node {
        final Runnable task;
        final CompletableFuture<Void> future = new CompletableFuture<>();
        Node(Runnable task) { this.task = task; }
    }

    static final class Shard {
        final ConcurrentHashMap<Object, AtomicReference<Node>> tails = new ConcurrentHashMap<>();
        final ExecutorService worker;
        Shard(ExecutorService worker) { this.worker = worker; }
    }

    private final List<Shard> shards;
    private final int shardMask;
    private final AtomicInteger roundRobin = new AtomicInteger();

    // Metrics (6 LongAdder)
    private final LongAdder submittedCount = new LongAdder();
    private final LongAdder executionCount = new LongAdder();
    private final LongAdder failureCount = new LongAdder();
    private final LongAdder retryCount = new LongAdder();
    private final LongAdder queueDepth = new LongAdder();
    private final LongAdder activeTasks = new LongAdder();

    public ShardedLockFreeMultiKeyExecutor(int shardCount) {
        if (Integer.bitCount(shardCount) != 1) {
            throw new IllegalArgumentException("Shard count must be power of two");
        }

        this.shards = new ArrayList<>(shardCount);
        this.shardMask = shardCount - 1;

        for (int i = 0; i < shardCount; i++) {
            int index = i;
            ExecutorService worker =
                    Executors.newSingleThreadExecutor(r -> new Thread(r, "shard-" + index));
            shards.add(new Shard(worker));
        }
    }

    public CompletableFuture<Void> submit(Collection<?> keys, Runnable task) {
        Objects.requireNonNull(keys);
        Objects.requireNonNull(task);

        submittedCount.increment();

        int size = keys.size();

        if (size == 0) {
            return submitZeroKey(task);
        }

        if (size == 1) {
            return submitSingleKey(keys.iterator().next(), task);
        }

        return submitMultiKey(keys, task);
    }

    // =============================
    // ZERO KEY (round-robin)
    // =============================
    private CompletableFuture<Void> submitZeroKey(Runnable task) {
        int index = roundRobin.getAndIncrement() & shardMask;
        Shard shard = shards.get(index);

        CompletableFuture<Void> future = new CompletableFuture<>();
        activeTasks.increment();

        shard.worker.execute(() -> {
            try {
                task.run();
                executionCount.increment();
                future.complete(null);
            } catch (Throwable t) {
                failureCount.increment();
                future.completeExceptionally(t);
            } finally {
                activeTasks.decrement();
            }
        });

        return future;
    }

    // =============================
    // SINGLE KEY
    // =============================
    private CompletableFuture<Void> submitSingleKey(Object key, Runnable task) {

        Shard shard = shardFor(key);

        AtomicReference<Node> ref =
                shard.tails.computeIfAbsent(key, k -> new AtomicReference<>());

        Node prev = ref.get();
        Node newNode = new Node(task);

        while (!ref.compareAndSet(prev, newNode)) {
            retryCount.increment();
            prev = ref.get();
        }

        queueDepth.increment();

        CompletableFuture<Void> dependency =
                prev == null ? CompletableFuture.completedFuture(null) : prev.future;

        dependency.whenCompleteAsync((v, ex) -> {
            queueDepth.decrement();
            activeTasks.increment();

            try {
                if (ex != null) {
                    failureCount.increment();
                    newNode.future.completeExceptionally(ex);
                    return;
                }

                task.run();
                executionCount.increment();
                newNode.future.complete(null);
            } catch (Throwable t) {
                failureCount.increment();
                newNode.future.completeExceptionally(t);
            } finally {
                activeTasks.decrement();
            }
        }, shard.worker);

        return newNode.future;
    }

    // =============================
    // MULTI KEY
    // =============================
    private CompletableFuture<Void> submitMultiKey(Collection<?> keys, Runnable task) {

        List<Shard> shardList = new ArrayList<>();
        List<AtomicReference<Node>> refs = new ArrayList<>();
        List<Node> prevNodes = new ArrayList<>();

        for (Object key : keys) {
            Shard shard = shardFor(key);
            shardList.add(shard);

            AtomicReference<Node> ref =
                    shard.tails.computeIfAbsent(key, k -> new AtomicReference<>());

            refs.add(ref);
            prevNodes.add(ref.get());
        }

        Node newNode = new Node(task);

        boolean success = false;
        while (!success) {
            success = true;
            for (int i = 0; i < refs.size(); i++) {
                if (!refs.get(i).compareAndSet(prevNodes.get(i), newNode)) {
                    retryCount.increment();
                    prevNodes.set(i, refs.get(i).get());
                    success = false;
                    break;
                }
            }
        }

        queueDepth.increment();

        CompletableFuture<?>[] deps = prevNodes.stream()
                .filter(Objects::nonNull)
                .map(n -> n.future)
                .toArray(CompletableFuture[]::new);

        CompletableFuture.allOf(deps)
                .whenCompleteAsync((v, ex) -> {
                    queueDepth.decrement();
                    activeTasks.increment();

                    try {
                        if (ex != null) {
                            failureCount.increment();
                            newNode.future.completeExceptionally(ex);
                            return;
                        }

                        task.run();
                        executionCount.increment();
                        newNode.future.complete(null);
                    } catch (Throwable t) {
                        failureCount.increment();
                        newNode.future.completeExceptionally(t);
                    } finally {
                        activeTasks.decrement();
                    }
                }, shardList.get(0).worker);

        return newNode.future;
    }

    private Shard shardFor(Object key) {
        int hash = Murmur3.hash32(key.toString().getBytes(), 0);
        return shards.get(hash & shardMask);
    }

    public Map<String, Long> metrics() {
        Map<String, Long> m = new LinkedHashMap<>();
        m.put("submitted", submittedCount.sum());
        m.put("executed", executionCount.sum());
        m.put("failed", failureCount.sum());
        m.put("retry", retryCount.sum());
        m.put("queueDepth", queueDepth.sum());
        m.put("activeTasks", activeTasks.sum());
        return m;
    }

    public void resetMetrics() {
        submittedCount.reset();
        executionCount.reset();
        failureCount.reset();
        retryCount.reset();
        queueDepth.reset();
        activeTasks.reset();
    }

    public void shutdown() {
        for (Shard shard : shards) {
            shard.worker.shutdown();
        }
    }
}
