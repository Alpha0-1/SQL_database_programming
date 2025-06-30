/*
 * File: 0-dimensional_modeling.sql
 * Author: Alpha0-1
 * Description: Introduction to dimensional modeling concepts
 * 
 * Dimensional modeling is a design technique for databases intended to support
 * end-user queries in a data warehouse. It focuses on delivering data that's
 * understandable to business users and provides fast query performance.
 * 
 * Key Concepts:
 * - Facts: Measurable, quantitative data (sales amount, quantity, etc.)
 * - Dimensions: Context for facts (time, location, product, customer)
 * - Grain: Level of detail in fact table
 * - Surrogate Keys: System-generated unique identifiers
 */

-- Sales Analysis Dimensional Model

-- Create a sample business scenario: Retail Sales Analysis
-- This demonstrates the basic concepts of dimensional modeling

/*
 * DIMENSION TABLES
 * These tables contain descriptive attributes that provide context to facts
 */

-- Time Dimension: Provides temporal context
CREATE TABLE DIM_TIME (
    time_key INTEGER PRIMARY KEY,           -- Surrogate key
    date_actual DATE NOT NULL,              -- Natural key
    day_of_week VARCHAR(10),
    day_of_month INTEGER,
    day_of_year INTEGER,
    week_of_year INTEGER,
    month_name VARCHAR(10),
    month_number INTEGER,
    quarter INTEGER,
    year INTEGER,
    is_weekend BOOLEAN,
    is_holiday BOOLEAN
);

-- Product Dimension: Product hierarchy and attributes
CREATE TABLE DIM_PRODUCT (
    product_key INTEGER PRIMARY KEY,        -- Surrogate key
    product_id VARCHAR(20) NOT NULL,        -- Natural key (business key)
    product_name VARCHAR(100),
    category VARCHAR(50),
    subcategory VARCHAR(50),
    brand VARCHAR(50),
    supplier VARCHAR(100),
    unit_cost DECIMAL(10,2),
    unit_price DECIMAL(10,2),
    product_status VARCHAR(20)
);

-- Customer Dimension: Customer demographics and segmentation
CREATE TABLE DIM_CUSTOMER (
    customer_key INTEGER PRIMARY KEY,       -- Surrogate key
    customer_id VARCHAR(20) NOT NULL,       -- Natural key
    customer_name VARCHAR(100),
    customer_type VARCHAR(20),              -- Individual, Corporate
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50),
    region VARCHAR(50),
    customer_segment VARCHAR(30),           -- Premium, Standard, Basic
    registration_date DATE
);

-- Store Dimension: Store location and attributes
CREATE TABLE DIM_STORE (
    store_key INTEGER PRIMARY KEY,          -- Surrogate key
    store_id VARCHAR(10) NOT NULL,          -- Natural key
    store_name VARCHAR(100),
    store_type VARCHAR(30),                 -- Mall, Standalone, Online
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50),
    region VARCHAR(50),
    store_size_sqft INTEGER,
    opening_date DATE
);

/*
 * FACT TABLE
 * Contains measurable business metrics and foreign keys to dimensions
 */

-- Sales Fact Table: Core business measurements
CREATE TABLE FACT_SALES (
    -- Composite primary key from dimension foreign keys
    time_key INTEGER NOT NULL,
    product_key INTEGER NOT NULL,
    customer_key INTEGER NOT NULL,
    store_key INTEGER NOT NULL,
    
    -- Additional degenerate dimensions (transaction level info)
    transaction_id VARCHAR(20),
    line_item_number INTEGER,
    
    -- Facts (measures) - quantitative data
    quantity_sold INTEGER,
    unit_price DECIMAL(10,2),
    discount_amount DECIMAL(10,2),
    sales_amount DECIMAL(12,2),               -- Extended price
    cost_amount DECIMAL(12,2),                -- Cost of goods sold
    profit_amount DECIMAL(12,2),              -- Calculated: sales - cost
    
    -- Foreign key constraints
    FOREIGN KEY (time_key) REFERENCES DIM_TIME(time_key),
    FOREIGN KEY (product_key) REFERENCES DIM_PRODUCT(product_key),
    FOREIGN KEY (customer_key) REFERENCES DIM_CUSTOMER(customer_key),
    FOREIGN KEY (store_key) REFERENCES DIM_STORE(store_key),
    
    -- Composite primary key
    PRIMARY KEY (time_key, product_key, customer_key, store_key, transaction_id, line_item_number)
);

/*
 * SAMPLE DATA INSERTION
 * Demonstrate how dimensional model supports business queries
 */

-- Insert sample time dimension data
INSERT INTO DIM_TIME VALUES
(20240101, '2024-01-01', 'Monday', 1, 1, 1, 'January', 1, 1, 2024, FALSE, TRUE),
(20240102, '2024-01-02', 'Tuesday', 2, 2, 1, 'January', 1, 1, 2024, FALSE, FALSE),
(20240103, '2024-01-03', 'Wednesday', 3, 3, 1, 'January', 1, 1, 2024, FALSE, FALSE);

-- Insert sample product dimension data
INSERT INTO DIM_PRODUCT VALUES
(1, 'PROD001', 'Wireless Headphones', 'Electronics', 'Audio', 'TechBrand', 'TechSupplier', 45.00, 89.99, 'Active'),
(2, 'PROD002', 'Running Shoes', 'Footwear', 'Athletic', 'SportBrand', 'ShoeSupplier', 35.00, 79.99, 'Active'),
(3, 'PROD003', 'Coffee Maker', 'Appliances', 'Kitchen', 'HomeBrand', 'HomeSupplier', 55.00, 129.99, 'Active');

-- Insert sample customer dimension data
INSERT INTO DIM_CUSTOMER VALUES
(1, 'CUST001', 'John Smith', 'Individual', 'New York', 'NY', 'USA', 'Northeast', 'Premium', '2023-01-15'),
(2, 'CUST002', 'Jane Doe', 'Individual', 'Los Angeles', 'CA', 'USA', 'West', 'Standard', '2023-03-20'),
(3, 'CUST003', 'Corporate ABC', 'Corporate', 'Chicago', 'IL', 'USA', 'Midwest', 'Premium', '2022-11-10');

-- Insert sample store dimension data
INSERT INTO DIM_STORE VALUES
(1, 'ST001', 'Downtown Mall Store', 'Mall', 'New York', 'NY', 'USA', 'Northeast', 2500, '2020-01-15'),
(2, 'ST002', 'West Coast Outlet', 'Standalone', 'Los Angeles', 'CA', 'USA', 'West', 3000, '2019-05-20'),
(3, 'ST003', 'Online Store', 'Online', 'Virtual', 'Virtual', 'USA', 'National', 0, '2018-01-01');

-- Insert sample fact data
INSERT INTO FACT_SALES VALUES
(20240101, 1, 1, 1, 'TXN001', 1, 2, 89.99, 5.00, 174.98, 90.00, 84.98),
(20240102, 2, 2, 2, 'TXN002', 1, 1, 79.99, 0.00, 79.99, 35.00, 44.99),
(20240103, 3, 3, 3, 'TXN003', 1, 1, 129.99, 10.00, 119.99, 55.00, 64.99);

/*
 * SAMPLE BUSINESS QUERIES
 * Demonstrate the power of dimensional modeling for analytics
 */

-- Query 1: Total sales by product category and month
SELECT 
    p.category,
    t.month_name,
    t.year,
    SUM(f.sales_amount) as total_sales,
    SUM(f.quantity_sold) as total_quantity,
    COUNT(*) as transaction_count
FROM FACT_SALES f
JOIN DIM_PRODUCT p ON f.product_key = p.product_key
JOIN DIM_TIME t ON f.time_key = t.time_key
GROUP BY p.category, t.month_name, t.year
ORDER BY t.year, t.month_number, total_sales DESC;

-- Query 2: Customer profitability analysis by region
SELECT 
    c.region,
    c.customer_segment,
    COUNT(DISTINCT c.customer_key) as customer_count,
    SUM(f.sales_amount) as total_revenue,
    SUM(f.profit_amount) as total_profit,
    AVG(f.profit_amount) as avg_profit_per_transaction
FROM FACT_SALES f
JOIN DIM_CUSTOMER c ON f.customer_key = c.customer_key
GROUP BY c.region, c.customer_segment
ORDER BY total_profit DESC;

-- Query 3: Store performance comparison
SELECT 
    s.store_name,
    s.store_type,
    s.region,
    SUM(f.sales_amount) as total_sales,
    SUM(f.profit_amount) as total_profit,
    (SUM(f.profit_amount) / SUM(f.sales_amount)) * 100 as profit_margin_pct
FROM FACT_SALES f
JOIN DIM_STORE s ON f.store_key = s.store_key
GROUP BY s.store_key, s.store_name, s.store_type, s.region
ORDER BY total_sales DESC;

/*
 * KEY DIMENSIONAL MODELING PRINCIPLES DEMONSTRATED:
 * 
 * 1. Surrogate Keys: Each dimension uses system-generated keys
 * 2. Natural Keys: Business keys are preserved for reference
 * 3. Denormalization: Dimensions contain hierarchical data in single tables
 * 4. Grain Definition: Each fact record represents one line item of a sale
 * 5. Additive Facts: Measures can be summed across any dimension
 * 6. Conformed Dimensions: Dimensions can be shared across fact tables
 * 7. Business-Friendly: Structure mirrors how business users think about data
 */
