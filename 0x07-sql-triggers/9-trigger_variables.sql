-- 9-trigger_variables.sql
-- Use of NEW and OLD variables in triggers

CREATE TABLE reviews (
    review_id INT PRIMARY KEY,
    content TEXT
);

CREATE TABLE review_log (
    review_id INT,
    old_content TEXT,
    new_content TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER trg_review_update
AFTER UPDATE ON reviews
FOR EACH ROW
BEGIN
    INSERT INTO review_log (review_id, old_content, new_content)
    VALUES (OLD.review_id, OLD.content, NEW.content);
END;//
DELIMITER ;

INSERT INTO reviews VALUES (1, 'Initial review');
UPDATE reviews SET content = 'Updated review' WHERE review_id = 1;
SELECT * FROM review_log;
