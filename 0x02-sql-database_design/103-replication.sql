-- 103-replication.sql: Basic Replication Setup (Conceptual)

-- Replication provides high availability and read scaling

-- Physical Replication (Streaming)
-- Configuration done in postgresql.conf and pg_hba.conf
-- Not executable here; this is conceptual.

-- Logical Replication Example:

-- Publisher node
CREATE PUBLICATION my_publication FOR TABLE users;

-- Subscriber node
CREATE SUBSCRIPTION my_subscription
    CONNECTION 'host=pubhost port=5432 dbname=mydb user=replica'
    PUBLICATION my_publication;
