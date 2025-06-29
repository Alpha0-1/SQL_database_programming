-- 3-before_update.sql
-- BEFORE UPDATE trigger: Validate or adjust data before updating

CREATE TABLE inventory (
    item_id INT PRIMARY KEY,
    quantity INT
);

DELIMITER //
CREATE TRIGGER trg_before_update_inventory
BEFORE UPDATE ON inventory
FOR EACH ROW
BEGIN
    IF NEW.quantity < 0 THEN
        SET NEW.quantity = 0; -- Avoid negative quantities
    END IF;
END;//
DELIMITER ;

INSERT INTO inventory VALUES (1, 10);
UPDATE inventory SET quantity = -5 WHERE item_id = 1;
SELECT * FROM inventory;

