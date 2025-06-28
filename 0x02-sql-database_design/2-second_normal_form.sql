-- 2-second_normal_form.sql: Demonstration of Second Normal Form (2NF)

-- 2NF requires the table to be in 1NF and ensures that all non-key attributes are fully dependent on the entire primary key.

-- Violation of 2NF
CREATE TABLE IF NOT EXISTS order_details_violates_2nf (
    order_id INT,
    item_id INT,
    customer_name TEXT, -- Partially depends on order_id only
    PRIMARY KEY (order_id, item_id)
);

-- Fix by splitting into two tables
CREATE TABLE IF NOT EXISTS orders (
    order_id SERIAL PRIMARY KEY,
    customer_name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    item_name TEXT NOT NULL,
    quantity INT CHECK (quantity > 0)
);

-- Insert sample data
INSERT INTO orders (customer_name) VALUES ('John Doe');
INSERT INTO order_items (order_id, item_name, quantity) VALUES (1, 'Keyboard', 1);

-- Query
SELECT o.order_id, o.customer_name, oi.item_name, oi.quantity
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id;
