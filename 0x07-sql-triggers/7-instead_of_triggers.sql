-- 7-instead_of_triggers.sql
-- INSTEAD OF trigger for views

CREATE TABLE archived_data (
    data_id INT PRIMARY KEY,
    info TEXT
);

CREATE VIEW v_archived AS
SELECT * FROM archived_data;

DELIMITER //
CREATE TRIGGER trg_instead_of_insert_archived
INSTEAD OF INSERT ON v_archived
FOR EACH ROW
BEGIN
    INSERT INTO archived_data (data_id, info)
    VALUES (NEW.data_id, NEW.info);
END;//
DELIMITER ;

INSERT INTO v_archived VALUES (1, 'Old record');
SELECT * FROM archived_data;
