#!/bin/bash
set -e

BACKUP_DIR="backups/$(date +%Y%m%d%H%M)"
mkdir -p "$BACKUP_DIR"

echo "Backing up all databases..."

# MySQL Backup
docker exec mysql_db mysqldump -u root -prootpass school_db > "$BACKUP_DIR/mysql_school_db.sql"

# PostgreSQL Backup
docker exec postgres_db pg_dump -U sql_user school_db > "$BACKUP_DIR/postgres_school_db.sql"

# SQLite Backup
cp data/school.db "$BACKUP_DIR/sqlite_school_db.db"

echo "Backup completed at $BACKUP_DIR"
