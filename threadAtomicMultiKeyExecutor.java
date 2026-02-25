import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;
import java.util.concurrent.atomic.LongAdder;
import java.util.stream.Collectors;

/**
 * A true Lock-Free Multi-Key Executor using Java Atomic packages.
 */
public class AtomicMultiKeyExecutor implements AutoCloseable {

    private static final AtomicInteger EXECUTOR_ID_COUNTER = new AtomicInteger();

    private final ConcurrentHashMap<Object, AtomicReference<CompletableFuture<Void>>> keyTails = new ConcurrentHashMap<>();
    private final ExecutorService executor;
    private final boolean cleanupEnabled;
    private final int executorId;

    private final ConcurrentLinkedQueue<SubmissionDescriptor> submissionQueue = new ConcurrentLinkedQueue<>();
    private final AtomicBoolean isDraining = new AtomicBoolean(false);

    private final LongAdder submittedNoKeyCount = new LongAdder();
    private final LongAdder submittedSingleKeyCount = new LongAdder();
    private final LongAdder submittedMultiKeyCount = new LongAdder();
    private final LongAdder executedCount = new LongAdder();
    private final LongAdder failedCount = new LongAdder();
    private final LongAdder cleanupCount = new LongAdder();

  
    private static class SubmissionDescriptor {
        final Set<Object> keys;
        final Runnable task;
        final CompletableFuture<Void> thisFuture;
        final int type;

        SubmissionDescriptor(Set<Object> keys, Runnable task, CompletableFuture<Void> thisFuture, int type) {
            this.keys = keys;
            this.task = task;
            this.thisFuture = thisFuture;
            this.type = type;
        }
    }

    public AtomicMultiKeyExecutor(int threadCount) {
        this(threadCount, true);
    }

    public AtomicMultiKeyExecutor(int threadCount, boolean cleanupEnabled) {
        this.executorId = EXECUTOR_ID_COUNTER.getAndIncrement();
        AtomicInteger threadIdCounter = new AtomicInteger();

        this.executor = Executors.newFixedThreadPool(threadCount, r -> {
            String name = String.format("atomic-exec-%d-worker-%d", executorId, threadIdCounter.getAndIncrement());
            Thread t = new Thread(r, name);
            t.setDaemon(false);
            return t;
        });
        this.cleanupEnabled = cleanupEnabled;
    }

    public CompletableFuture<Void> submit(Collection<?> keys, Runnable task) {
        Objects.requireNonNull(keys, "Keys cannot be null");
        Objects.requireNonNull(task, "Task cannot be null");

        CompletableFuture<Void> thisFuture = new CompletableFuture<>();
        int type = keys.isEmpty() ? 0 : (keys.size() == 1 ? 1 : 2);

        submissionQueue.offer(new SubmissionDescriptor(
            keys.isEmpty() ? Collections.emptySet() : new HashSet<>(keys),
            task,
            thisFuture,
            type
        ));

        tryDrain();

         return thisFuture;
    }

    private void tryDrain() {
        if (isDraining.compareAndSet(false, true)) {
            try {
                SubmissionDescriptor desc;
                while ((desc = submissionQueue.poll()) != null) {
                    processSubmission(desc);
                }
            } finally {
                isDraining.set(false);
                if (!submissionQueue.isEmpty()) {
                    tryDrain();
                }
            }
        }
    }

    private void processSubmission(SubmissionDescriptor desc) {
        if (desc.type == 0) {
            submittedNoKeyCount.increment();
            CompletableFuture.runAsync(() -> executeTask(desc.task, desc.thisFuture), executor);
            return;
        }

        if (desc.type == 1) {
            submittedSingleKeyCount.increment();
        } else {
            submittedMultiKeyCount.increment();
        }

        List<Object> sortedKeys = desc.keys.stream()
            .sorted(this::compareKeys)
            .collect(Collectors.toList());

        List<CompletableFuture<Void>> dependencies = new ArrayList<>(sortedKeys.size());

        for (Object key : sortedKeys) {
            keyTails.compute(key, (k, ref) -> {
                if (ref == null) {
                    ref = new AtomicReference<>(CompletableFuture.completedFuture(null));
                }
                CompletableFuture<Void> prev = ref.getAndSet(desc.thisFuture);
                if (prev != null && !prev.isDone()) {

                    dependencies.add(prev);
                }
                return ref;
            });
        }

        CompletableFuture<Void> combinedDep = (dependencies.isEmpty())
            ? CompletableFuture.completedFuture(null)
            : CompletableFuture.allOf(dependencies.toArray(new CompletableFuture[0]));

        combinedDep.handleAsync((v, ex) -> {
            executeTask(desc.task, desc.thisFuture);
            return null;
        }, executor);

        if (cleanupEnabled) {
            desc.thisFuture.thenRun(() -> cleanup(sortedKeys, desc.thisFuture));
        }
    }

    private void executeTask(Runnable task, CompletableFuture<Void> targetFuture) {
        try {
            task.run();
            executedCount.increment();
            targetFuture.complete(null);
        } catch (Throwable t) {
            failedCount.increment();
            targetFuture.completeExceptionally(t);
        }
    }

    private void cleanup(List<Object> keys, CompletableFuture<Void> finishedFuture) {
        for (Object key : keys) {
            keyTails.computeIfPresent(key, (k, ref) -> {
                if (ref.get() == finishedFuture) {
                    cleanupCount.increment();
                    return null;
                }
                return ref;
            });
        }
    }

    private int compareKeys(Object o1, Object o2) {
        if (o1 == o2) return 0;
        int h1 = o1.hashCode();
        int h2 = o2.hashCode();
        if (h1 != h2) return Integer.compare(h1, h2);
        int i1 = System.identityHashCode(o1);
        int i2 = System.identityHashCode(o2);
        if (i1 != i2) return Integer.compare(i1, i2);
        return o1.toString().compareTo(o2.toString());
    }

    public Map<String, Long> getMetrics() {
        Map<String, Long> m = new LinkedHashMap<>();
        m.put("submitted_total", submittedNoKeyCount.sum() + submittedSingleKeyCount.sum() + submittedMultiKeyCount.sum());
        m.put("executed", executedCount.sum());
        m.put("active_keys", (long) keyTails.size());
        return m;
    }

    @Override
    public void close() {
        executor.shutdown();
        try {
            if (!executor.awaitTermination(5, TimeUnit.SECONDS)) {
                executor.shutdownNow();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            executor.shutdownNow();
        }
    }
}      
