/*
  Title: COMMIT and ROLLBACK
  Description: Explains how COMMIT and ROLLBACK work in SQL transactions, including practical examples.
  Learning Objectives:
  1. Understand the COMMIT and ROLLBACK commands.
  2. Learn when to use COMMIT versus ROLLBACK.
  3. Practice using these commands in real-world scenarios.
*/

-- Create a sample table
CREATE TABLE Products (
  ProductID INT NOT NULL AUTO_INCREMENT,
  ProductName VARCHAR(100) NOT NULL,
  Price DECIMAL(10,2) NOT NULL,
  Quantity INT NOT NULL,
  PRIMARY KEY (ProductID)
);

-- Starting a transaction
START TRANSACTION;

-- Insert a new product
INSERT INTO Products (ProductName, Price, Quantity)
VALUES ('Laptop', 999.99, 10);

-- Update the quantity of an existing product
UPDATE Products
SET Quantity = Quantity + 5
WHERE ProductName = 'Phone';

-- Verify the changes before committing
SELECT * FROM Products;

-- COMMIT the transaction
COMMIT;

-- Rollback example
START TRANSACTION;

-- Attempt to insert duplicate product (assuming ProductName is unique)
INSERT INTO Products (ProductName, Price, Quantity)
VALUES ('Laptop', 999.99, 10);

-- This will cause an error if 'Laptop' already exists
-- Assuming the error occurs, ROLLBACK the transaction
ROLLBACK;

-- Verify that the transaction was rolled back
SELECT * FROM Products;

-- Clean up
DROP TABLE Products;
