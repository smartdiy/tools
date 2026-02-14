# High-Performance Spring Boot Copilot Instruction

You are assisting in a latency-sensitive, high-throughput Spring Boot backend.

All code must prioritize:
- Minimal database round trips
- Batch operations over per-row operations
- Short transaction scope
- Memory efficiency
- Horizontal scalability

---

## 1. Recursive Call Graph Analysis

When given a method:

1. Build full recursive call graph.
2. Trace into:
   - Service
   - Repository
   - @Mapper
   - DAO
   - Util classes
3. Detect all:
   - JDBC calls (JdbcTemplate, Connection, PreparedStatement)
   - JPA calls (save, findById, flush, EntityManager)
   - MyBatis calls (@Mapper, SqlSession, XML mapper)

Output call tree before refactoring.

---

## 2. Detect Performance Anti-Patterns

Always flag:

- DB call inside for/while loop
- stream().forEach() with DB call
- save() inside loop
- select inside loop (N+1)
- flush() inside loop
- Lazy loading N+1
- Missing fetch join
- Missing pagination for large reads
- Repeated single-row query instead of IN clause
- MyBatis ExecutorType.SIMPLE for bulk operations
- Transaction started inside loop
- Logging inside tight loops

If any DB call exists inside loop, assume performance bug unless explicitly justified.

---

## 3. Mandatory Refactoring Strategy

Refactor to batch operations:

### JPA
- saveAll()
- Bulk JPQL update
- fetch join
- @EntityGraph
- Enable:
  spring.jpa.properties.hibernate.jdbc.batch_size=500

### JDBC
- JdbcTemplate.batchUpdate()
- PreparedStatement batching

### MyBatis
- <foreach> batch insert/update
- ExecutorType.BATCH
- Replace repeated select with IN query

Batch size guideline: 200–1000

---

## 4. Transaction Rules

- @Transactional only at service layer
- No transaction inside loops
- Keep transactions short
- Avoid flush() unless required
- Avoid long-running transactions

---

## 5. Throughput Optimization

Prefer:
- Bulk writes
- Pagination
- Streaming reads
- Async processing when safe
- Avoid unnecessary object creation
- Avoid blocking I/O
- Use connection pool efficiently

---

## 6. Logging & Tracing Rules

- Use @Slf4j
- No debug logging inside tight loops
- Log summary only
- Add execution time measurement
- Add OpenTelemetry spans for heavy operations

---

## 7. Required Output Format

When refactoring:

1. Call Tree
2. Issues Found
3. Refactored Code
4. Why It Improves Performance
5. Estimated Round Trip Reduction
