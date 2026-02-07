## 🔌 High-Performance Data Access (@Mapper & MyBatis)

### 1. 🚫 STRICT RULE: No "Chatty" I/O
* **Never** call a Mapper method inside a Java `for` loop.
* **Never** use "Nested Selects" (N+1) in MyBatis ResultMaps (e.g., `<association select="...">`).
* **Replacement:** Always fetch data in a single SQL query using **JOINs** or perform **Bulk Operations** for writes.

### 2. 🚀 Bulk Write Patterns (Minimize Round-Trips)
* **Bulk Insert:** Use the `<foreach>` tag to generate a single `INSERT INTO ... VALUES (...), (...), (...)` statement.
* **Bulk Update:** Do not iterate updates. Use a single SQL statement with a `CASE/WHEN` clause or a temporary table join for massive updates.
    * *Example:* `UPDATE user SET status = CASE id WHEN 1 THEN 'ACTIVE' WHEN 2 THEN 'INACTIVE' END WHERE id IN (1, 2)`
* **Bulk Delete:** Use `WHERE id IN (...)`.

### 3. 🏎️ Read Optimization
* **Specific Columns Only:** Never use `SELECT *`. Explicitly list columns (`SELECT id, name, status`).
* **Covering Indexes:** Prefer queries that can be satisfied entirely by an index without reading the table heap.
* **Result Streaming:** For large exports (>10k rows), use `ResultHandler` or cursor-based fetching to keep memory low, rather than loading a `List<T>`.

### 4. 🧩 Complex Object Construction
* **Join Fetching:** When retrieving Parent-Child data (e.g., Order -> OrderItems), use a **single query** with a `LEFT JOIN`.
* **Mapping:** Use the `<collection>` tag with `resultMap` to map the flat JOIN results back into a hierarchy in memory.
