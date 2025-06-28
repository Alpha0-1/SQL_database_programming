-- schemas/inventory_schema.sql: Inventory Management Schema

CREATE TABLE IF NOT EXISTS warehouses (
    warehouse_id SERIAL PRIMARY KEY,
    location TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS products (
    product_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS inventory (
    warehouse_id INT REFERENCES warehouses(warehouse_id),
    product_id INT REFERENCES products(product_id),
    quantity INT,
    PRIMARY KEY (warehouse_id, product_id)
);
