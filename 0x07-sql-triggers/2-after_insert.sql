-- 2-after_insert.sql
-- AFTER INSERT trigger: Used to log or perform actions after insert

CREATE TABLE product (
    product_id INT PRIMARY KEY,
    name VARCHAR(50),
    price DECIMAL(8,2)
);

CREATE TABLE product_log (
    log_id SERIAL PRIMARY KEY,
    product_name VARCHAR(50),
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER trg_after_product_insert
AFTER INSERT ON product
FOR EACH ROW
BEGIN
    INSERT INTO product_log (product_name)
    VALUES (NEW.name);
END;//
DELIMITER ;

INSERT INTO product VALUES (1, 'Laptop', 1200.00);
SELECT * FROM product_log;


