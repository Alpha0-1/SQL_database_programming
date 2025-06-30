# Use official PostgreSQL image as base
FROM postgres:14

# Copy custom init script
COPY init.sql /docker-entrypoint-initdb.d/
