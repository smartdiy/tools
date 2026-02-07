# GitHub Copilot Instructions for This Repository

You are assisting with a high-throughput, low-latency Spring Boot application.
Always optimize for performance, correctness, and maintainability, and follow Google Java Style Guide conventions [web:6][web:7][web:13].

## General Coding Rules

- Use Java, Spring Boot, and Lombok in this project.
- Use `@Slf4j` from Lombok for logging instead of manually declaring loggers [web:6].
- Keep logging minimal on hot paths and in tight loops; favor summary logs over per-item logs [web:6].
- Prefer constructor injection over field injection.
- Follow Google Java Style: clear naming, 100‑char line limit, consistent brace placement, Javadoc on public APIs [web:7][web:13].

## Logging, AOP, and Tracing

When creating or updating business logic:

- Implement cross-cutting logging with Spring AOP instead of scattering `log.info` in every method [web:6][web:9][web:12].
- Create an aspect for:
  - Method entry/exit for service and controller layers.
  - Execution time measurement (log slow methods with WARN).
  - Exception logging with correlation IDs.
- Use MDC or tracing context (e.g., OpenTelemetry / Sleuth-style) to propagate request IDs across threads whenever possible [web:6].
- Prefer asynchronous or buffered logging where supported (e.g., Logback async appenders) to reduce I/O overhead [web:6].

### Example Guidance for Logging Aspect

When asked to add logging:

- Create an `@Aspect` with an `@Around` advice on service/controller packages.
- Log:
  - Class and method name.
  - Key parameters (only those safe and small).
  - Latency in milliseconds.
- Avoid logging large payloads or collections; log sizes and identifiers instead.

## Database Access

When generating or updating persistence code:

- Use MyBatis `@Mapper` interfaces for database access.
- Use batch operations whenever possible for write-heavy operations (e.g., `insertBatch`, `updateBatch`) to reduce round-trips.
- Avoid N+1 query patterns; fetch in bulk and use `IN` queries where appropriate.
- Ensure SQL uses appropriate indexes (e.g., on frequently filtered columns) and avoid `SELECT *` in mappers.
- Be mindful of transaction boundaries; keep transactions as small and focused as possible.

## Performance and Concurrency

For any new feature, default to designs that maximize throughput and minimize latency:

- Use non-blocking or asynchronous patterns where reasonable, such as:
  - Spring’s async methods, `CompletableFuture`, or reactive APIs where appropriate.
  - Asynchronous messaging (e.g., Kafka, RabbitMQ) for decoupled workloads.
- Avoid unnecessary object allocations in hot paths.
- Avoid expensive reflection or AOP on extremely hot methods unless justified; consider targeted pointcuts [web:9][web:12].
- Do not add excessive logging in performance-critical sections; log only what’s needed for observability [web:6].

## Messaging and Integration

When adding integration with external systems:

- Prefer asynchronous message-based communication or event-driven patterns if business requirements allow.
- Encapsulate external calls behind interfaces to make them easy to mock in unit tests.
- Implement timeouts, retries with backoff, and circuit breakers where appropriate.

## Testing Requirements

Every time you generate or modify application code, also:

- Create or update **JUnit unit tests** for the changed code.
  - Use mocks for external dependencies (DB mappers, external clients, message brokers).
  - Verify loggable behavior indirectly through returned values or side effects unless log capturing is explicitly requested.
- Create or update **integration tests** when behavior spans multiple layers.
  - Spin up a test application context.
  - Use an actual test database (e.g., embedded or Testcontainers) or a dedicated test app for external connections.
  - For external services, create lightweight test apps or stubs instead of hitting real systems.

Whenever you change code:

- Re-verify and, if necessary, update all impacted tests.
- Ensure tests cover success paths, common error paths, and performance-sensitive branches.

## Behavior for `/review the code`

When the user types `/review the code`:

1. Focus on:
   - Compliance with Google Java Style Guide (formatting, naming, structure) [web:7][web:13].
   - Performance and scalability concerns, especially:
     - Excessive logging or blocking I/O in hot paths.
     - Inefficient database access (N+1 queries, missing batching, large unbounded result sets).
     - Misuse of collections or algorithms with poor complexity.
     - Poor use of threads or asynchronous libraries that could cause contention.

2. If you find style or performance issues:
   - Propose **refactored code snippets** that resolve the issues.
   - Also provide any necessary updates to related unit tests and integration tests so they remain valid.
   - Keep refactors minimal and focused; avoid large, unrelated changes.

3. Always remind the user:
   - To commit or otherwise checkpoint the existing code before applying your suggested changes,
   - So they can easily roll back if needed.

### Example reminder to include in reviews

> Before applying these refactorings, create a commit or checkpoint of your current code so you can easily roll back if any change does not behave as expected.

## Documentation and Comments

- Favor clear code over excessive comments.
- Add Javadoc for public classes, interfaces, and methods, explaining intent and performance considerations when relevant.
- Document any non-obvious performance optimizations or trade-offs.

## What to Avoid

- Do not introduce heavy dependencies purely for convenience if they hurt startup time or memory footprint.
- Do not add verbose logging at `INFO` level in tight loops or high-frequency paths.
- Do not expose blocking calls on public APIs that are meant to be asynchronous or reactive without clear justification.

