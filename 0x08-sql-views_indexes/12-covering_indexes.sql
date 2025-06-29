/*
 * Title: Covering Indexes
 * Description: Demonstrates how to create and use covering indexes
 * 
 * Covering indexes include all the columns needed for a query, improving performance by:
 * - Reducing the need to access the underlying table
 * - Speeding up SELECT operations
 * - Minimizing disk I/O
 */

-- Step 1: Create a sample table
CREATE TABLE books (
    book_id INT PRIMARY KEY,
    title VARCHAR(200),
    author VARCHAR(100),
    publication_date DATE,
    price DECIMAL(10,2)
);

-- Step 2: Populate sample data
INSERT INTO books VALUES
    (1, 'The Great Gatsby', 'F. Scott Fitzgerald', '1925-01-01', 14.99),
    (2, 'To Kill a Mockingbird', 'Harper Lee', '1960-07-11', 12.99),
    (3, '1984', 'George Orwell', '1949-06-08', 9.99);

-- Step 3: Create a covering index for popular author queries
CREATE INDEX idx_author_price 
ON books(author, price);

-- Step 4: Query that benefits from the covering index
SELECT title, author, price 
FROM books 
WHERE author = 'Harper Lee';

-- Step 5: Verify the index usage (PostgreSQL-specific)
EXPLAIN SELECT title, author, price 
FROM books 
WHERE author = 'Harper Lee';

/*
 * Explanation:
 * - Covering indexes include all columns needed for a query
 * - They minimize the need to access the underlying table
 * - Use covering indexes for frequently queried columns
 */
