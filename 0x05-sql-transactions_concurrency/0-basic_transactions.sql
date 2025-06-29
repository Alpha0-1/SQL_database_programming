/*
  Title: Basic Transaction Syntax
  Description: Demonstrates the basic structure of SQL transactions, including the use of BEGIN, COMMIT, and ROLLBACK.
  Learning Objectives:
  1. Understand the purpose of transactions in SQL.
  2. Learn how to start, commit, and rollback transactions.
  3. Recognize the importance of transaction control in maintaining data integrity.
*/

-- Creating a sample table
CREATE TABLE Employees (
  EmployeeID INT NOT NULL AUTO_INCREMENT,
  FirstName VARCHAR(50) NOT NULL,
  LastName VARCHAR(50) NOT NULL,
  Salary DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (EmployeeID)
);

/*
  Starting a transaction with BEGIN
  Transactions allow a series of SQL operations to be executed as a single logical unit of work.
  This ensures consistency and integrity in the database.
*/

START TRANSACTION;

-- Inserting a new employee
INSERT INTO Employees (FirstName, LastName, Salary)
VALUES ('John', 'Doe', 50000.00);

-- Updating the salary of another employee
UPDATE Employees
SET Salary = Salary * 1.10
WHERE LastName = 'Smith';

/*
  Committing the transaction
  COMMIT saves all changes made during the transaction and makes them permanent in the database.
  It's essential to commit after completing all desired operations.
*/

COMMIT;

/*
  Rolling back a transaction (for demonstration)
  ROLLBACK undoes all changes made during the current transaction and reverts the database to its previous state.
  This is useful when an error occurs or when the operations are not completed successfully.
*/

-- Starting another transaction
START TRANSACTION;

-- Inserting another record
INSERT INTO Employees (FirstName, LastName, Salary)
VALUES ('Jane', 'Doe', 60000.00);

-- Demonstrating ROLLBACK
ROLLBACK;

-- After rollback, the last INSERT will not be saved.

/*
  Testing the table
  Use the following SELECT statement to view the current state of the Employees table.
*/

SELECT * FROM Employees;

-- Cleaning up (optional)
DROP TABLE Employees;
