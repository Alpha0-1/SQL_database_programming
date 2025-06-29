-- 5-before_delete.sql
-- BEFORE DELETE trigger: Prevent delete if condition not met

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    status VARCHAR(20)
);

DELIMITER //
CREATE TRIGGER trg_before_delete_order
BEFORE DELETE ON orders
FOR EACH ROW
BEGIN
    IF OLD.status = 'processing' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot delete processing orders';
    END IF;
END;//
DELIMITER ;

INSERT INTO orders VALUES (1, 'processing'), (2, 'cancelled');
-- DELETE FROM orders WHERE order_id = 1; -- This will fail
DELETE FROM orders WHERE order_id = 2; -- This will succeed
