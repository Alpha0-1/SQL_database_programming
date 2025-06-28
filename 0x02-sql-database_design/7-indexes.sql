-- 7-indexes.sql: Creating and Using Indexes for Performance

-- Indexes improve query performance on frequently searched columns

-- Create index on email field
CREATE INDEX idx_users_email ON users(email);

-- Composite index
CREATE INDEX idx_order_items ON order_items(order_id, item_id);

-- Use EXPLAIN ANALYZE to see if index is used
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'alice@example.com';

-- Drop index if no longer needed
-- DROP INDEX idx_users_email;

-- Caution: Too many indexes can slow down writes
