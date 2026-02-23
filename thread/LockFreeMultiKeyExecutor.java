import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

public class LockFreeMultiKeyExecutor implements AutoCloseable {

    private final ThreadPoolExecutor executor;
    private final ConcurrentHashMap<String, AtomicReference<Node>> keyTails =
            new ConcurrentHashMap<>();
    private final AtomicBoolean running = new AtomicBoolean(true);

    // ---------------- Metrics ----------------
    private final LongAdder totalSubmissions = new LongAdder();
    private final LongAdder singleKeySubmissions = new LongAdder();
    private final LongAdder multiKeySubmissions = new LongAdder();
    private final LongAdder retryCount = new LongAdder();
    private final LongAdder taskExecutionCount = new LongAdder();
    private final LongAdder taskFailureCount = new LongAdder();

    private static final Node EMPTY =
            new Node(CompletableFuture.completedFuture(null));

    private static final class Node {
        final CompletableFuture<Void> future;
        Node(CompletableFuture<Void> future) {
            this.future = future;
        }
    }

    public LockFreeMultiKeyExecutor(int threads, int queueCapacity) {
        this.executor = new ThreadPoolExecutor(
                threads,
                threads,
                0L,
                TimeUnit.MILLISECONDS,
                new ArrayBlockingQueue<>(queueCapacity),
                namedThreadFactory("lockfree-multikey-worker"),
                new ThreadPoolExecutor.CallerRunsPolicy()
        );
    }

    private static ThreadFactory namedThreadFactory(String baseName) {
        ThreadFactory defaultFactory = Executors.defaultThreadFactory();
        AtomicInteger counter = new AtomicInteger(1);
        return r -> {
            Thread t = defaultFactory.newThread(r);
            t.setName(baseName + "-" + counter.getAndIncrement());
            return t;
        };
    }

    public CompletableFuture<Void> submit(String key, Runnable task) {
        return submit(Collections.singletonList(key), task);
    }

    public CompletableFuture<Void> submit(Collection<String> keys, Runnable task) {

        if (!running.get()) {
            throw new RejectedExecutionException("Executor is shutting down");
        }

        totalSubmissions.increment();

        if (keys == null || keys.isEmpty()) {
            return CompletableFuture.runAsync(task, executor);
        }

        List<String> unique = new ArrayList<>(new HashSet<>(keys));

        if (unique.size() == 1) {
            singleKeySubmissions.increment();
            return submitSingle(unique.get(0), task);
        }

        multiKeySubmissions.increment();
        return submitMulti(unique, task);
    }

    private CompletableFuture<Void> submitSingle(String key, Runnable task) {

        AtomicReference<Node> tailRef =
                keyTails.computeIfAbsent(key, k -> new AtomicReference<>(EMPTY));

        while (true) {
            Node prev = tailRef.get();

            CompletableFuture<Void> promise = new CompletableFuture<>();
            Node newNode = new Node(promise);

            if (tailRef.compareAndSet(prev, newNode)) {

                prev.future.whenCompleteAsync((v, ex) -> {
                    if (ex != null) {
                        promise.completeExceptionally(ex);
                        taskFailureCount.increment();
                        return;
                    }
                    try {
                        task.run();
                        taskExecutionCount.increment();
                        promise.complete(null);
                    } catch (Throwable t) {
                        taskFailureCount.increment();
                        promise.completeExceptionally(t);
                    }
                }, executor);

                return promise;
            }

            retryCount.increment();
        }
    }

    private CompletableFuture<Void> submitMulti(List<String> keys, Runnable task) {

        while (true) {

            int size = keys.size();

            List<AtomicReference<Node>> refs = new ArrayList<>(size);
            List<Node> prevNodes = new ArrayList<>(size);

            for (String key : keys) {
                AtomicReference<Node> ref =
                        keyTails.computeIfAbsent(key, k -> new AtomicReference<>(EMPTY));
                refs.add(ref);
                prevNodes.add(ref.get());
            }

            CompletableFuture<Void> promise = new CompletableFuture<>();
            Node newNode = new Node(promise);

            boolean success = true;

            for (int i = 0; i < size; i++) {
                if (!refs.get(i).compareAndSet(prevNodes.get(i), newNode)) {
                    success = false;
                    break;
                }
            }

            if (!success) {
                retryCount.increment();
                continue;
            }

            CompletableFuture<?>[] deps = new CompletableFuture[size];
            for (int i = 0; i < size; i++) {
                deps[i] = prevNodes.get(i).future;
            }

            CompletableFuture<Void> combined =
                    CompletableFuture.allOf(deps);

            combined.whenCompleteAsync((v, ex) -> {
                if (ex != null) {
                    taskFailureCount.increment();
                    promise.completeExceptionally(ex);
                    return;
                }
                try {
                    task.run();
                    taskExecutionCount.increment();
                    promise.complete(null);
                } catch (Throwable t) {
                    taskFailureCount.increment();
                    promise.completeExceptionally(t);
                }
            }, executor);

            return promise;
        }
    }

    // ---------------- Metrics Snapshot ----------------

    public ExecutorMetrics getMetrics() {
        return new ExecutorMetrics(
                totalSubmissions.sum(),
                singleKeySubmissions.sum(),
                multiKeySubmissions.sum(),
                retryCount.sum(),
                taskExecutionCount.sum(),
                taskFailureCount.sum(),
                executor.getQueue().size(),
                executor.getActiveCount(),
                executor.getPoolSize()
        );
    }

    public static final class ExecutorMetrics {
        public final long totalSubmissions;
        public final long singleKeySubmissions;
        public final long multiKeySubmissions;
        public final long retryCount;
        public final long taskExecutionCount;
        public final long taskFailureCount;
        public final int queueDepth;
        public final int activeThreads;
        public final int poolSize;

        public ExecutorMetrics(long totalSubmissions,
                               long singleKeySubmissions,
                               long multiKeySubmissions,
                               long retryCount,
                               long taskExecutionCount,
                               long taskFailureCount,
                               int queueDepth,
                               int activeThreads,
                               int poolSize) {
            this.totalSubmissions = totalSubmissions;
            this.singleKeySubmissions = singleKeySubmissions;
            this.multiKeySubmissions = multiKeySubmissions;
            this.retryCount = retryCount;
            this.taskExecutionCount = taskExecutionCount;
            this.taskFailureCount = taskFailureCount;
            this.queueDepth = queueDepth;
            this.activeThreads = activeThreads;
            this.poolSize = poolSize;
        }

        @Override
        public String toString() {
            return "ExecutorMetrics{" +
                    "totalSubmissions=" + totalSubmissions +
                    ", singleKeySubmissions=" + singleKeySubmissions +
                    ", multiKeySubmissions=" + multiKeySubmissions +
                    ", retryCount=" + retryCount +
                    ", taskExecutionCount=" + taskExecutionCount +
                    ", taskFailureCount=" + taskFailureCount +
                    ", queueDepth=" + queueDepth +
                    ", activeThreads=" + activeThreads +
                    ", poolSize=" + poolSize +
                    '}';
        }
    }

    @Override
    public void close() {
        running.set(false);
        executor.shutdown();
    }
}
