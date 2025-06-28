-- first_normal_form.sql: Demonstration of First Normal Form (1NF)

-- 1NF requires that each column contains atomic values (no repeating groups).

-- Unnormalized Table
CREATE TABLE IF NOT EXISTS orders_unnormalized (
    order_id INT PRIMARY KEY,
    customer_name TEXT,
    items TEXT[] -- Array violates 1NF
);

-- Normalize by creating a junction table
CREATE TABLE IF NOT EXISTS customers (
    customer_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS items (
    item_id SERIAL PRIMARY KEY,
    product_name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    order_date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS order_items (
    order_id INT REFERENCES orders(order_id),
    item_id INT REFERENCES items(item_id),
    quantity INT CHECK (quantity > 0),
    PRIMARY KEY (order_id, item_id)
);

-- Insert example normalized data
INSERT INTO customers (name) VALUES ('Alice'), ('Bob');
INSERT INTO items (product_name) VALUES ('Laptop'), ('Mouse');

INSERT INTO orders (customer_id) VALUES (1), (2);
INSERT INTO order_items (order_id, item_id, quantity) VALUES (1, 1, 2), (1, 2, 5);

-- Query normalized data
SELECT o.order_id, c.name AS customer, i.product_name, oi.quantity
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN items i ON oi.item_id = i.item_id;
