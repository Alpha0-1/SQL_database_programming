-- 6-foreign_keys.sql: Managing Foreign Key Constraints

-- Ensures referential integrity between tables

-- Create referenced table first
CREATE TABLE IF NOT EXISTS categories (
    category_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

-- Referencing table
CREATE TABLE IF NOT EXISTS products (
    product_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    category_id INT REFERENCES categories(category_id) ON DELETE CASCADE
);

-- Insert valid data
INSERT INTO categories (name) VALUES ('Electronics');
INSERT INTO products (name, category_id) VALUES ('Laptop', 1);

-- Invalid foreign key fails
-- INSERT INTO products (name, category_id) VALUES ('Invalid', 99); -- ERROR

-- Deleting category deletes associated products due to ON DELETE CASCADE
-- DELETE FROM categories WHERE category_id = 1;
