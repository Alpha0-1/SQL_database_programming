-- MySQL Data Types Example

-- Using various MySQL data types
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2),
    description TEXT,
    is_available BOOLEAN,
    stock_quantity SMALLINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inserting values with different data types
INSERT INTO products (name, price, description, is_available, stock_quantity)
VALUES
    ('Laptop', 999.99, 'High-performance laptop', TRUE, 10),
    ('Mouse', 19.99, 'Wireless mouse', FALSE, 0);

-- View the inserted data
SELECT * FROM products;
