-- 6-after_delete.sql
-- AFTER DELETE trigger: Log deleted record information

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE customer_deletions (
    customer_id INT,
    deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER trg_after_delete_customer
AFTER DELETE ON customers
FOR EACH ROW
BEGIN
    INSERT INTO customer_deletions (customer_id)
    VALUES (OLD.customer_id);
END;//
DELIMITER ;

INSERT INTO customers VALUES (1, 'Eve');
DELETE FROM customers WHERE customer_id = 1;
SELECT * FROM customer_deletions;


