/*
  Filename: 5-postgresql_extensions.sql
  Description: Utilizing PostgreSQL extensions for enhanced functionality
  Author: Alpha0-1
*/

-- Step 1: Connect to the database
\c basic_db;

-- Step 2: Install the pgcrypto extension
CREATE EXTENSION pgcrypto;

-- Step 3: Use pgcrypto to hash a password
SELECT crypt('password', gen_salt('bf'));

-- Step 4: Install the hstore extension
CREATE EXTENSION hstore;

-- Step 5: Create a table with hstore
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name TEXT,
    attributes HSTORE
);

-- Step 6: Insert data with hstore
INSERT INTO products (name, attributes)
VALUES
('Laptop', '"brand" => "Dell", "price" => "999.99"');

-- Step 7: Query hstore data
SELECT * FROM products
WHERE attributes ->> 'brand' = 'Dell';

-- Step 8: Install the tablefunc extension
CREATE EXTENSION tablefunc;

-- Step 9: Use crosstab function example
SELECT * FROM crosstab(
    'SELECT department, year, salary
     FROM employee Salaries
     ORDER BY 1,2'
) AS ct(
    department TEXT,
    "2022" DECIMAL,
    "2023" DECIMAL
);

/*
  Exercise:
  1. Install the `unaccent` extension and use it for case-insensitive searches
  2. Practice using the `jsonb` extension with advanced JSON operations
  3. Explore other extensions like `postgis` for spatial data
*/

-- Cleanup
-- DROP EXTENSION pgcrypto, hstore, tablefunc;
-- DROP TABLE products;
