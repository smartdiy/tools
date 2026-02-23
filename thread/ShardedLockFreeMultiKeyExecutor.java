import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

public class ShardedLockFreeMultiKeyExecutor implements AutoCloseable {

    private static final class Node {
        final Runnable task;
        final CompletableFuture<Void> future;

        Node(Runnable task) {
            this.task = task;
            this.future = new CompletableFuture<>();
        }
    }

    // ================= Shard Structure =================

    private static final class Shard {

        final ConcurrentHashMap<String, AtomicReference<Node>> tails =
                new ConcurrentHashMap<>();

        final ExecutorService worker;

        Shard(ExecutorService worker) {
            this.worker = worker;
        }
    }

    private final Shard[] shards;

    private final AtomicBoolean running = new AtomicBoolean(true);

    // Metrics
    private final LongAdder submissionCount = new LongAdder();
    private final LongAdder retryCount = new LongAdder();
    private final LongAdder executionCount = new LongAdder();

    // ================= Constructor =================

    public ShardedLockFreeMultiKeyExecutor(int threadsPerShard) {

        int cpu = Runtime.getRuntime().availableProcessors();
        int shardCount = Math.max(2, cpu);

        this.shards = new Shard[shardCount];

        for (int i = 0; i < shardCount; i++) {

            ExecutorService worker = new ThreadPoolExecutor(
                    threadsPerShard,
                    threadsPerShard,
                    0L,
                    TimeUnit.MILLISECONDS,
                    new ArrayBlockingQueue<>(10000),
                    namedThreadFactory("dag-shard-" + i),
                    new ThreadPoolExecutor.CallerRunsPolicy()
            );

            shards[i] = new Shard(worker);
        }
    }

    private int shardIndex(String key) {
        return Math.abs(key.hashCode()) % shards.length;
    }

    private static ThreadFactory namedThreadFactory(String base) {
        ThreadFactory def = Executors.defaultThreadFactory();
        AtomicInteger counter = new AtomicInteger(1);

        return r -> {
            Thread t = def.newThread(r);
            t.setName(base + "-" + counter.getAndIncrement());
            return t;
        };
    }

    // ================= Public API =================

    public CompletableFuture<Void> submit(String key, Runnable task) {
        return submit(Collections.singletonList(key), task);
    }

    public CompletableFuture<Void> submit(Collection<String> keys, Runnable task) {

        if (!running.get()) {
            throw new RejectedExecutionException();
        }

        submissionCount.increment();

        List<String> unique = new ArrayList<>(new HashSet<>(keys));
        unique.sort(Comparator.naturalOrder());

        if (unique.size() == 1) {
            return submitSingle(unique.get(0), task);
        }

        return submitMulti(unique, task);
    }

    // ================= Single Key Fast Path =================

    private CompletableFuture<Void> submitSingle(String key, Runnable task) {

        Shard shard = shards[shardIndex(key)];
        AtomicReference<Node> tailRef =
                shard.tails.computeIfAbsent(key,
                        k -> new AtomicReference<>(null));

        while (true) {

            Node prev = tailRef.get();

            Node newNode = new Node(task);

            if (tailRef.compareAndSet(prev, newNode)) {

                CompletableFuture<Void> dependency =
                        prev == null ? CompletableFuture.completedFuture(null)
                                : prev.future;

                dependency.whenCompleteAsync((v, ex) -> {

                    if (ex != null) {
                        newNode.future.completeExceptionally(ex);
                        return;
                    }

                    try {
                        task.run();
                        executionCount.increment();
                        newNode.future.complete(null);
                    } catch (Throwable t) {
                        newNode.future.completeExceptionally(t);
                    }

                }, shard.worker);

                return newNode.future;
            }

            retryCount.increment();
        }
    }

    // ================= Multi-Key Path =================

    private CompletableFuture<Void> submitMulti(List<String> keys, Runnable task) {

        while (true) {

            List<Shard> shardList = new ArrayList<>();
            List<AtomicReference<Node>> refs = new ArrayList<>();
            List<Node> prevNodes = new ArrayList<>();

            for (String key : keys) {

                Shard shard = shards[shardIndex(key)];

                AtomicReference<Node> ref =
                        shard.tails.computeIfAbsent(key,
                                k -> new AtomicReference<>(null));

                shardList.add(shard);
                refs.add(ref);
                prevNodes.add(ref.get());
            }

            Node newNode = new Node(task);

            // CAS commit
            boolean success = true;

            for (int i = 0; i < refs.size(); i++) {

                if (!refs.get(i).compareAndSet(prevNodes.get(i), newNode)) {
                    success = false;
                    break;
                }
            }

            if (!success) {
                retryCount.increment();
                continue;
            }

            CompletableFuture<?>[] deps =
                    prevNodes.stream()
                            .map(n -> n == null ?
                                    CompletableFuture.completedFuture(null)
                                    : n.future)
                            .toArray(CompletableFuture[]::new);

            CompletableFuture.allOf(deps)
                    .whenCompleteAsync((v, ex) -> {

                        if (ex != null) {
                            newNode.future.completeExceptionally(ex);
                            return;
                        }

                        try {
                            task.run();
                            executionCount.increment();
                            newNode.future.complete(null);
                        } catch (Throwable t) {
                            newNode.future.completeExceptionally(t);
                        }

                    }, shardList.get(0).worker);

            return newNode.future;
        }
    }

    // ================= Lifecycle =================

    @Override
    public void close() {
        running.set(false);

        for (Shard shard : shards) {
            shard.worker.shutdown();
        }
    }
}
