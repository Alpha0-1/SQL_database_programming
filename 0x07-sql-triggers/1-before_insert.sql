-- 1-before_insert.sql
-- BEFORE INSERT trigger: Used to validate or modify data before it is inserted

CREATE TABLE users (
    user_id INT PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    created_at TIMESTAMP
);

DELIMITER //
CREATE TRIGGER trg_before_insert_user
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
    -- Set created_at timestamp if not provided
    IF NEW.created_at IS NULL THEN
        SET NEW.created_at = CURRENT_TIMESTAMP;
    END IF;
END;//
DELIMITER ;

INSERT INTO users (user_id, username) VALUES (1, 'JohnDoe');
SELECT * FROM users;

