# SQL Database Design

This repository contains practical SQL scripts demonstrating various aspects of **relational database design**. Each file builds upon foundational concepts and progresses toward advanced topics.

## File Structure

| File | Description |
|------|-------------|
| `0x02-sql-database_design` | Entry point / overview |
| `0-normalization.sql` | Introduction to normalization |
| `1-first_normal_form.sql` | 1NF examples |
| `2-second_normal_form.sql` | 2NF examples |
| `3-third_normal_form.sql` | 3NF examples |
| `4-entity_relationship.sql` | ER modeling implementation |
| `5-primary_keys.sql` | Primary key constraints |
| `6-foreign_keys.sql` | Foreign key relationships |
| `7-indexes.sql` | Index creation and usage |
| `8-views.sql` | View creation |
| `9-stored_procedures.sql` | Stored procedure examples |
| `10-triggers.sql` | Trigger implementation |
| `11-functions.sql` | User-defined functions |
| `12-data_types.sql` | Data type optimization |
| `100-complex_schema.sql` | Complex multi-table schema |
| `101-partitioning.sql` | Table partitioning |
| `102-sharding.sql` | Sharding strategies |
| `103-replication.sql` | Replication setup |
| `/schemas/*.sql` | Predefined schema templates |

## Usage Instructions

1. Install PostgreSQL or any compatible RDBMS.
2. Navigate to the desired `.sql` file.
3. Run the file using:
   ```bash
   psql -f filename.sql
