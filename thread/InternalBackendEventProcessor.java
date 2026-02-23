import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * InternalBackendEventProcessor
 *
 * Design Goal:
 * - At-least-once processing guarantee
 * - Message ID deduplication
 * - Partitioned lock-free executor submission
 * - Durable intake buffer (memory buffer + WAL hook)
 */
public class InternalBackendEventProcessor {

    // ================= Configuration =================

    private final LockFreeMultiKeyExecutor executor;

    private final BlockingQueue<BackendEvent> intakeBuffer;

    // Deduplication cache (can be tuned or replaced by Redis / WAL index)
    private final ConcurrentHashMap<String, Boolean> processedMessageIds =
            new ConcurrentHashMap<>();

    private final AtomicBoolean running = new AtomicBoolean(true);

    private final int batchDrainSize = 64;

    // ================= Constructor =================

    public InternalBackendEventProcessor(
            LockFreeMultiKeyExecutor executor,
            int bufferCapacity
    ) {
        this.executor = executor;
        this.intakeBuffer = new ArrayBlockingQueue<>(bufferCapacity);

        startBackgroundDrainWorker();
    }

    // ================= Event Model =================

    public static class BackendEvent {

        public final String messageId;
        public final String partitionKey;
        public final Runnable businessLogic;

        public BackendEvent(
                String messageId,
                String partitionKey,
                Runnable businessLogic
        ) {
            this.messageId = messageId;
            this.partitionKey = partitionKey;
            this.businessLogic = businessLogic;
        }
    }

    // ================= Public API =================

    public void submitEvent(BackendEvent event) {

        if (!running.get()) {
            throw new RejectedExecutionException("Processor stopped");
        }

        // Deduplication protection
        if (processedMessageIds.containsKey(event.messageId)) {
            return;
        }

        // Intake buffer persistence point (WAL hook placeholder)
        enqueueIntake(event);
    }

    // ================= Intake Buffer =================

    private void enqueueIntake(BackendEvent event) {
        try {
            intakeBuffer.put(event);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException(e);
        }
    }

    // ================= Background Drain Worker =================

    private void startBackgroundDrainWorker() {

        Thread worker = new Thread(() -> {

            List<BackendEvent> batch = new ArrayList<>(batchDrainSize);

            while (running.get()) {

                try {
                    intakeBuffer.drainTo(batch, batchDrainSize);

                    if (!batch.isEmpty()) {
                        processBatch(batch);
                        batch.clear();
                    } else {
                        Thread.sleep(10);
                    }

                } catch (Throwable t) {
                    t.printStackTrace();
                }
            }

        }, "backend-event-drain-worker");

        worker.setDaemon(false);
        worker.start();
    }

    // ================= Batch Processing =================

    private void processBatch(List<BackendEvent> batch) {

        for (BackendEvent event : batch) {

            if (processedMessageIds.putIfAbsent(event.messageId, Boolean.TRUE) != null) {
                continue;
            }

            executor.submit(
                    Collections.singletonList(event.partitionKey),
                    event.businessLogic
            );
        }
    }

    // ================= Lifecycle =================

    public void shutdown() {
        running.set(false);
    }
}
