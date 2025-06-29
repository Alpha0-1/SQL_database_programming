-- 4-after_update.sql
-- AFTER UPDATE trigger: Log the changes made

CREATE TABLE salary (
    emp_id INT PRIMARY KEY,
    base_salary DECIMAL(10,2)
);

CREATE TABLE salary_changes (
    emp_id INT,
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2),
    changed_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER trg_after_update_salary
AFTER UPDATE ON salary
FOR EACH ROW
BEGIN
    INSERT INTO salary_changes (emp_id, old_salary, new_salary)
    VALUES (OLD.emp_id, OLD.base_salary, NEW.base_salary);
END;//
DELIMITER ;

INSERT INTO salary VALUES (101, 4500);
UPDATE salary SET base_salary = 5000 WHERE emp_id = 101;
SELECT * FROM salary_changes;


