#!/bin/bash
set -e

echo "Setting up databases..."

# Setup MySQL
echo "Initializing MySQL..."
docker exec mysql_db mysql -u root -prootpass < databases/mysql/init.sql

# Setup PostgreSQL
echo "Initializing PostgreSQL..."
docker exec postgres_db psql -U sql_user -d school_db -f databases/postgresql/init.sql

# Setup SQLite
echo "Initializing SQLite..."
sqlite3 data/school.db < databases/sqlite/setup.sql

echo "All databases initialized successfully!"
