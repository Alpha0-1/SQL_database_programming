-- 102-sharding.sql: Sharding Strategies (Conceptual)

-- Note: Sharding is typically handled at the infrastructure level.
-- PostgreSQL doesn't natively support sharding but you can simulate it.

-- Logical Shards (Example: Sharding by Region)

-- Shard 1: North America
CREATE TABLE IF NOT EXISTS users_na (
    user_id SERIAL PRIMARY KEY,
    name TEXT
);

-- Shard 2: Europe
CREATE TABLE IF NOT EXISTS users_eu (
    user_id SERIAL PRIMARY KEY,
    name TEXT
);

-- Application-level routing required
-- SELECT * FROM users_na WHERE user_id = 1;
-- SELECT * FROM users_eu WHERE user_id = 1;
