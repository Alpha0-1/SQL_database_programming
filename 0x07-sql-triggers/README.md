# SQL Triggers

This module provides hands-on learning materials focused on **SQL triggers**, including practical examples, debugging strategies, and best practices.

## Prerequisites

- PostgreSQL installed and running
- Basic understanding of SQL
- psql command-line tool or any SQL client

## Topics Covered

| File | Topic |
|------|-------|
| `0-basic_triggers.sql` | Basic trigger syntax |
| `1-before_insert.sql` | BEFORE INSERT triggers |
| `2-after_insert.sql` | AFTER INSERT triggers |
| `3-before_update.sql` | BEFORE UPDATE triggers |
| `4-after_update.sql` | AFTER UPDATE triggers |
| `5-before_delete.sql` | BEFORE DELETE triggers |
| `6-after_delete.sql` | AFTER DELETE triggers |
| `7-instead_of_triggers.sql` | INSTEAD OF triggers |
| `8-trigger_conditions.sql` | Conditional triggers |
| `9-trigger_variables.sql` | NEW and OLD variables |
| `10-audit_triggers.sql` | Audit trail implementation |
| `11-validation_triggers.sql` | Data validation |
| `12-business_logic_triggers.sql` | Business rule enforcement |
| `100-trigger_performance.sql` | Performance optimization |
| `101-trigger_debugging.sql` | Debugging techniques |
| `102-trigger_best_practices.sql` | Best practices |

## Tips

- Run each script step-by-step in `psql`
- Inspect the system catalog (`pg_trigger`, `pg_proc`) for metadata
- Use `RAISE NOTICE` to trace execution flow
- Always test edge cases

## Warnings

- Triggers can cause cascading effects
- Overuse may lead to hard-to-debug issues
- Always document your triggers

## References

- [PostgreSQL Trigger Documentation](https://www.postgresql.org/docs/current/plpgsql-trigger.html )
- [Best Practices for Using Database Triggers](https://wiki.postgresql.org/wiki/Trigger_Best_Practices )
- [SQL Style Guide](https://www.sqlstyle.guide/ )
