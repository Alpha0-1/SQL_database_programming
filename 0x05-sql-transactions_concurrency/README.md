# SQL Transactions & Concurrency

This repository contains SQL scripts demonstrating various aspects of **transactions** and **concurrency control** in relational databases, particularly focusing on PostgreSQL.

## Contents

| File | Description |
|------|-------------|
| `0-basic_transactions.sql` | Basic transaction structure |
| `1-commit_rollback.sql` | COMMIT and ROLLBACK usage |
| `2-savepoints.sql` | Using savepoints inside transactions |
| `3-isolation_levels.sql` | Transaction isolation levels |
| `4-deadlock_handling.sql` | Deadlock simulation and prevention |
| `5-locking_mechanisms.sql` | Explicit row and table locking |
| `6-optimistic_locking.sql` | Optimistic concurrency control |
| `7-pessimistic_locking.sql` | Pessimistic concurrency control |
| `8-concurrent_updates.sql` | Managing concurrent data updates |
| `9-race_conditions.sql` | Preventing race conditions |
| `10-acid_properties.sql` | ACID compliance demonstration |
| `11-distributed_transactions.sql` | Introduction to distributed transactions |
| `12-two_phase_commit.sql` | Two-phase commit protocol |
| `100-performance_locking.sql` | Performance considerations with locking |
| `101-monitoring_locks.sql` | Monitoring locks in PostgreSQL |
| `102-troubleshooting.sql` | Diagnosing transaction issues |

## How to Use

1. **Ensure PostgreSQL is running**.
2. **Connect to your target database** using `psql`.
3. Run individual files using `\i filename.sql`.

> 💡 Tip: You can run multiple sessions (`psql`) to simulate concurrent access and test locking behavior.

## License

MIT License – Free to use and modify for educational purposes.
