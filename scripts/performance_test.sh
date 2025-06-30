#!/bin/bash
set -e

echo "Starting performance test suite..."

# Sample test: Count rows in students table across all DBs
for db in mysql postgresql sqlite; do
    echo "Testing $db..."
    case $db in
        mysql)
            docker exec mysql_db mysql -u root -prootpass -e "SELECT COUNT(*) FROM school_db.students;"
            ;;
        postgresql)
            docker exec postgres_db psql -U sql_user -d school_db -c "SELECT COUNT(*) FROM students;"
            ;;
        sqlite)
            sqlite3 data/school.db "SELECT COUNT(*) FROM students;"
            ;;
    esac
done

echo "Performance test complete."
