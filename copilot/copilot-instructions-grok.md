# GitHub Copilot Custom Instructions – High-Performance Spring Boot

## Project Philosophy & Style
- We build **high-throughput, low-latency** Spring Boot applications.
- Performance, scalability, observability, and clean architecture are top priorities.
- Prefer **non-blocking**, **async**, and **reactive** patterns when it makes sense (especially in I/O bound operations).
- Follow **Google Java Style Guide** (2-space indent, no wildcard imports, clear naming, etc.).
- Use **Lombok** aggressively to reduce boilerplate (`@Data`, `@Slf4j`, `@RequiredArgsConstructor`, `@Builder`, etc.).
- Write **self-documenting code** with meaningful names — avoid unnecessary comments.

## Logging
- Always use **@Slf4j** from Lombok — never declare `private static final Logger log = ...`
- Log **method entry/exit** + execution time + important parameters using **AOP** (do not litter business code with logging).
- Use structured logging (JSON preferred in production) via Logback / LogstashEncoder.
- Log levels:
  - TRACE → very detailed (disabled in prod)
  - DEBUG → development & troubleshooting
  - INFO  → important business events, start/stop, metrics
  - WARN  → recoverable issues
  - ERROR → critical failures (with exception)

## AOP Logging & Tracing (Mandatory)
- Create and maintain a central **LoggingAspect** using @Aspect
- Log:
  - Method name, class, arguments (shortened if large)
  - Execution time (always)
  - Exceptions (with stack trace at ERROR level)
- Prefer **@Around** advice for controllers, services, and repositories
- If tracing is used (preferred): integrate **Micrometer Tracing** + **OpenTelemetry** or **Spring Cloud Sleuth + Zipkin/OTLP**
  - Annotate important methods with `@Observed` or `@SpanTag`

## Database Access
- Prefer **MyBatis** over Spring Data JPA for better control and performance
- Use **@Mapper** interface style (not XML if possible — prefer annotations)
- Use **batch operations** for bulk inserts/updates/deletes:
  - MyBatis: `BatchExecutor`, `foreach` + `batch` mode
  - JdbcTemplate: `batchUpdate()`
- Always use **HikariCP** connection pool (default)
- Enable JDBC batching in application.yml:
  ```yaml
  spring:
    datasource:
      hikari:
        maximum-pool-size: 20
      jdbc:
        batch-size: 500
