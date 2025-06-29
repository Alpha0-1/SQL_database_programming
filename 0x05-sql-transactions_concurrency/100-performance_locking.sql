-- Filename: 100-performance_locking.sql
-- Description: Understanding the impact of locking on database performance.

/*
NOTES:
- Locking mechanisms can degrade performance if not used properly.
- Row-level locking (as in InnoDB) is more efficient than table-level locking (as in MyISAM).

PREREQUISITES:
- Create a sample table with a few records.
*/

CREATE TABLE performance_locking (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50),
    balance DECIMAL(10,2)
);

-- Insert sample data
INSERT INTO performance_locking (name, balance) VALUES
('Alice', 1000.00),
('Bob', 2000.00),
('Charlie', 3000.00)
;

/*
Example 1: Row-level locking (good for performance)
This uses the FOR UPDATE clause to lock only the affected rows
*/

START TRANSACTION;
SELECT * FROM performance_locking WHERE id = 1 FOR UPDATE;
-- Simulate some processing delay
DO SLEEP(2);
UPDATE performance_locking SET balance = balance + 100 WHERE id = 1;
COMMIT;

/*
Example 2: Table-level locking (impacts performance)
Explicitly locking the entire table
*/

START TRANSACTION;
LOCK TABLES performance_locking WRITE;
-- Simulate processing
DO SLEEP(2);
UPDATE performance_locking SET balance = balance + 100;
UNLOCK TABLES;
COMMIT;

/*
OBSERVATIONS:
- Row-level locking allows concurrent updates on different rows.
- Table-level locking prevents any other transaction from accessing the table, leading to contention.
*/
