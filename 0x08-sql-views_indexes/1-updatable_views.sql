/*
 * Title: UpdatableViews
 * Description: Demonstrates how to create and use updatable views
 *
 * Not all views are updatable. For a view to be updatable:
 * - It must reference a single base table
 * - All columns of the underlying table must be included in the view
 * - Primary key constraints must be respected
 */

-- Step 1: Create a sample table
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    product_id INT,
    quantity INT,
    sale_date DATE
);

-- Step 2: Populate sample data
INSERT INTO sales VALUES
    (1, 101, 10, '2023-01-01'),
    (2, 102, 20, '2023-01-02');

-- Step 3: Create an updatable view
CREATE VIEW current_sales AS
SELECT 
    sale_id,
    product_id,
    quantity,
    sale_date
FROM sales
WHERE sale_date >= CURRENT_DATE - INTERVAL '7 days';

-- Step 4: Update data through the view
UPDATE current_sales
SET quantity = 15
WHERE sale_id = 1;

-- Verify the update
SELECT * FROM current_sales;

/*
 * Explanation:
 * - Updatable views provide a way to modify data through the view
 * - Care must be taken to ensure the view is constructed correctly
 * - Constraints like PRIMARY KEY must be respected
 */
