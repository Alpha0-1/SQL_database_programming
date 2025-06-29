/*
 * Title: Unique Indexes
 * Description: Shows how to create and use unique indexes to enforce data uniqueness
 * 
 * Unique indexes ensure that:
 * - No duplicate values exist in a column or set of columns
 * - Data integrity is maintained
 * - Duplicate detection is faster
 */

-- Step 1: Create a sample table
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    email VARCHAR(100),
    username VARCHAR(50)
);

-- Step 2: Create a unique index on the email column
CREATE UNIQUE INDEX idx_email ON users(email);

-- Step 3: Attempt to insert duplicate email (should fail)
INSERT INTO users VALUES
    (1, 'john@example.com', 'john123'),
    (2, 'john@example.com', 'john456');  -- Duplicate email error

-- Step 4: Query to demonstrate uniqueness
SELECT COUNT(*) FROM users
WHERE email = 'john@example.com';

/*
 * Explanation:
 * - Unique indexes enforce data uniqueness at the database level
 * - They prevent duplicate insertions
 * - Use them for columns that must be unique
 */
