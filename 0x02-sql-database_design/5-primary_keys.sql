-- 5-primary_keys.sql: Working with Primary Key Constraints

-- A primary key uniquely identifies each record in a table.

-- Auto-incremented primary key
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    email TEXT UNIQUE NOT NULL
);

-- Composite primary key
CREATE TABLE IF NOT EXISTS order_items (
    order_id INT,
    item_id INT,
    quantity INT,
    PRIMARY KEY (order_id, item_id)
);

-- Enforce uniqueness and not-null
INSERT INTO users (email) VALUES ('alice@example.com');
INSERT INTO order_items (order_id, item_id, quantity) VALUES (1, 101, 2);

-- Attempting duplicate PK will fail
-- INSERT INTO users (user_id, email) VALUES (1, 'bob@example.com'); -- ERROR
