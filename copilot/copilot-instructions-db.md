## 2. 💾 Database Specifics
- **Postgres:** Verify JDBC URL has `reWriteBatchedInserts=true`.
- **MySQL:** Verify JDBC URL has `rewriteBatchedStatements=true`.
- **MSSQL:** Verify JDBC URL has `useBulkCopyForBatchInsert=true`.
- **MongoDB:** When using `bulkWrite` or `insertMany`, ALWAYS prefer `ordered(false)` unless strict sequencing is required by business logic.
