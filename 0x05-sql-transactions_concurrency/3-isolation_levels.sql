/*
  Title: Transaction Isolation Levels
  Description: Demonstrates different transaction isolation levels and their effects on concurrent transactions.
  Learning Objectives:
  1. Understand different transaction isolation levels.
  2. Learn how to set and use transaction isolation levels.
  3. Recognize the implications of each isolation level on data consistency and performance.
*/

-- Create a sample table
CREATE TABLE Accounts (
  AccountID INT NOT NULL AUTO_INCREMENT,
  AccountHolder VARCHAR(50) NOT NULL,
  Balance DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (AccountID)
);

-- Insert initial data
INSERT INTO Accounts (AccountHolder, Balance)
VALUES ('Alice', 1000.00), ('Bob', 500.00);

-- Set isolation level to Read Committed
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Start Transaction 1
START TRANSACTION;

-- Read Alice's balance
SELECT * FROM Accounts WHERE AccountHolder = 'Alice';

-- Simultaneously, start Transaction 2 in another session
-- (Simulated here for demonstration)
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;

-- Update Bob's balance
UPDATE Accounts SET Balance = 600.00 WHERE AccountHolder = 'Bob';

-- Commit Transaction 2
COMMIT;

-- Back to Transaction 1, read Bob's balance
SELECT * FROM Accounts WHERE AccountHolder = 'Bob';

-- Observe that the change is visible because of Read Committed
-- Now, set isolation level to Repeatable Read
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Start Transaction 1 again
START TRANSACTION;

-- Read Alice's balance
SELECT * FROM Accounts WHERE AccountHolder = 'Alice';

-- Simultaneously, start Transaction 2
START TRANSACTION;

-- Update Bob's balance again
UPDATE Accounts SET Balance = 700.00 WHERE AccountHolder = 'Bob';

-- Commit Transaction 2
COMMIT;

-- Back to Transaction 1, read Bob's balance
SELECT * FROM Accounts WHERE AccountHolder = 'Bob';

-- Observe that the change is not visible due to Repeatable Read

-- Commit Transaction 1
COMMIT;

-- Clean up
DROP TABLE Accounts;
