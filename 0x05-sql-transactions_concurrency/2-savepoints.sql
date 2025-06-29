/*
  Title: Savepoint Usage
  Description: Illustrates the use of savepoints within SQL transactions to roll back to a specific point in the transaction without undoing the entire transaction.
  Learning Objectives:
  1. Understand how to create and use savepoints.
  2. Learn how to rollback to a savepoint.
  3. Recognize scenarios where savepoints are beneficial.
*/

-- Create a sample table
CREATE TABLE Transactions (
  TransactionID INT NOT NULL AUTO_INCREMENT,
  Description VARCHAR(200),
  Amount DECIMAL(10,2),
  TransactionDate DATE,
  PRIMARY KEY (TransactionID)
);

-- Starting a transaction
START TRANSACTION;

-- Inserting first transaction
INSERT INTO Transactions (Description, Amount, TransactionDate)
VALUES ('Office Supplies', 250.00, '2023-01-01');

-- Creating a savepoint
SAVEPOINT sp1;

-- Inserting second transaction
INSERT INTO Transactions (Description, Amount, TransactionDate)
VALUES ('Software License', 500.00, '2023-01-01');

-- Rolling back to savepoint sp1
ROLLBACK TO sp1;

-- Inserting a corrected transaction after rollback
INSERT INTO Transactions (Description, Amount, TransactionDate)
VALUES ('Software License Update', 750.00, '2023-01-01');

-- Committing the transaction
COMMIT;

-- Verify the final state of the Transactions table
SELECT * FROM Transactions;

-- Clean up
DROP TABLE Transactions;
