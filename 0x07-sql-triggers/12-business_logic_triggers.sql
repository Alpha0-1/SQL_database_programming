-- Create main table and related table
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    stock INT NOT NULL
);

CREATE TABLE sales (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    sale_date DATE DEFAULT CURRENT_DATE
);

-- Business Logic Trigger
DELIMITER $$

CREATE TRIGGER after_update_products
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
    IF NEW.stock < OLD.stock THEN
        INSERT INTO sales (product_id, quantity)
        VALUES (NEW.id, OLD.stock - NEW.stock);
    END IF;
END$$

DELIMITER ;

-- Test the trigger
INSERT INTO products (name, price, stock)
VALUES ('Laptop', 1000.00, 100);

UPDATE products
SET stock = 90
WHERE name = 'Laptop';

SELECT * FROM sales;

-- Cleanup
DROP TABLE sales;
DROP TABLE products;
