/*
 * File: 1-star_schema.sql
 * Author: Alpha0-1
 * Description: Star Schema implementation and design patterns
 * 
 * Star Schema is the simplest dimensional modeling approach where:
 * - Central fact table connects to dimension tables
 * - Dimensions are denormalized (flat tables)
 * - Resembles a star when visualized (fact at center, dimensions as points)
 * - Optimized for query performance and business user understanding
 * 
 * Advantages:
 * - Simple to understand and navigate
 * - Fast query performance (fewer joins)
 * - Easy to maintain and extend
 * - Optimized for OLAP and reporting tools
 */

-- Drop existing tables if they exist (for clean implementation)
DROP TABLE IF EXISTS FACT_ORDER_SALES CASCADE;
DROP TABLE IF EXISTS DIM_DATE CASCADE;
DROP TABLE IF EXISTS DIM_PRODUCT CASCADE;
DROP TABLE IF EXISTS DIM_CUSTOMER CASCADE;
DROP TABLE IF EXISTS DIM_GEOGRAPHY CASCADE;
DROP TABLE IF EXISTS DIM_SALES_CHANNEL CASCADE;

/*
 * STAR SCHEMA IMPLEMENTATION: E-COMMERCE SALES ANALYSIS
 * 
 * Business Case: Online retail company wants to analyze:
 * - Sales performance across different time periods
 * - Product performance and profitability
 * - Customer behavior and segmentation
 * - Geographic sales distribution
 * - Sales channel effectiveness
 */

/*
 * DIMENSION TABLES (Star Points)
 * Each dimension is denormalized - contains all hierarchical levels
 */

-- Date Dimension: Complete date hierarchy in single table
CREATE TABLE DIM_DATE (
    date_key INTEGER PRIMARY KEY,          -- YYYYMMDD format
    full_date DATE NOT NULL UNIQUE,
    
    -- Day level attributes
    day_of_week INTEGER,                   -- 1-7
    day_name VARCHAR(10),                  -- Monday, Tuesday, etc.
    day_of_month INTEGER,                  -- 1-31
    day_of_year INTEGER,                   -- 1-366
    
    -- Week level attributes
    week_of_year INTEGER,                  -- 1-53
    week_begin_date DATE,
    week_end_date DATE,
    
    -- Month level attributes
    month_number INTEGER,                  -- 1-12
    month_name VARCHAR(10),                -- January, February, etc.
    month_abbr VARCHAR(3),                 -- Jan, Feb, etc.
    
    -- Quarter level attributes
    quarter_number INTEGER,                -- 1-4
    quarter_name VARCHAR(2),               -- Q1, Q2, Q3, Q4
    
    -- Year level attributes
    year_number INTEGER,                   -- 2024, 2025, etc.
    
    -- Business calendar attributes
    is_weekend BOOLEAN,
    is_holiday BOOLEAN,
    holiday_name VARCHAR(50),
    fiscal_year INTEGER,
    fiscal_quarter INTEGER,
    fiscal_month INTEGER,
    
    -- Season attributes
    season VARCHAR(10)                     -- Spring, Summer, Fall, Winter
);

-- Product Dimension: Complete product hierarchy flattened
CREATE TABLE DIM_PRODUCT (
    product_key SERIAL PRIMARY KEY,        -- Surrogate key
    product_id VARCHAR(20) NOT NULL UNIQUE, -- Natural/Business key
    
    -- Product attributes
    product_name VARCHAR(100) NOT NULL,
    product_description TEXT,
    
    -- Product hierarchy (denormalized)
    department_name VARCHAR(50),           -- Electronics, Clothing, etc.
    category_name VARCHAR(50),             -- Laptops, Shirts, etc.
    subcategory_name VARCHAR(50),          -- Gaming Laptops, Dress Shirts, etc.
    
    -- Product details
    brand_name VARCHAR(50),
    supplier_name VARCHAR(100),
    
    -- Financial attributes
    standard_cost DECIMAL(10,2),
    list_price DECIMAL(10,2),
    
    -- Physical attributes
    color VARCHAR(30),
    size VARCHAR(20),
    weight_kg DECIMAL(8,3),
    
    -- Status and dates
    product_status VARCHAR(20),            -- Active, Discontinued, Pending
    launch_date DATE,
    discontinue_date DATE,
    
    -- Flags for easy filtering
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE
);

-- Customer Dimension: Customer attributes and segmentation
CREATE TABLE DIM_CUSTOMER (
    customer_key SERIAL PRIMARY KEY,       -- Surrogate key
    customer_id VARCHAR(20) NOT NULL UNIQUE, -- Natural key
    
    -- Personal information
    customer_name VARCHAR(100),
    customer_type VARCHAR(20),             -- Individual, Business
    
    -- Contact information (denormalized)
    email VARCHAR(100),
    phone VARCHAR(20),
    
    -- Geographic information (partially denormalized)
    address_line1 VARCHAR(100),
    address_line2 VARCHAR(100),
    city VARCHAR(50),
    state_province VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50),
    
    -- Customer segmentation
    customer_segment VARCHAR(30),          -- VIP, Premium, Standard, Basic
    credit_rating VARCHAR(10),             -- AAA, AA, A, B, C
    
    -- Business attributes
    registration_date DATE,
    first_purchase_date DATE,
    last_purchase_date DATE,
    
    -- Calculated attributes (updated periodically)
    total_lifetime_value DECIMAL(12,2),
    average_order_value DECIMAL(10,2),
    total_orders INTEGER,
    
    -- Status flags
    is_active BOOLEAN DEFAULT TRUE,
    is_corporate BOOLEAN DEFAULT FALSE
);

-- Geography Dimension: Location hierarchy for sales analysis
CREATE TABLE DIM_GEOGRAPHY (
    geography_key SERIAL PRIMARY KEY,      -- Surrogate key
    
    -- Geographic hierarchy (denormalized)
    country_code VARCHAR(3),               -- ISO country code
    country_name VARCHAR(50),
    
    region_name VARCHAR(50),               -- North America, Europe, etc.
    sub_region_name VARCHAR(50),           -- Western Europe, Southeast Asia, etc.
    
    state_province_code VARCHAR(10),
    state_province_name VARCHAR(50),
    
    city_name VARCHAR(50),
    postal_code VARCHAR(20),
    
    -- Geographic attributes
    time_zone VARCHAR(50),
    currency_code VARCHAR(3),
    
    -- Business attributes
    market_segment VARCHAR(30),            -- Developed, Emerging, Growth
    sales_territory VARCHAR(50),
    sales_region VARCHAR(50),
    
    -- Demographic data
    population INTEGER,
    gdp_per_capita DECIMAL(12,2)
);

-- Sales Channel Dimension: How sales are made
CREATE TABLE DIM_SALES_CHANNEL (
    channel_key SERIAL PRIMARY KEY,        -- Surrogate key
    channel_id VARCHAR(10) NOT NULL UNIQUE, -- Natural key
    
    -- Channel information
    channel_name VARCHAR(50),              -- Online, Retail Store, Phone, etc.
    channel_type VARCHAR(30),              -- Direct, Partner, Distributor
    channel_category VARCHAR(30),          -- Digital, Physical, Hybrid
    
    -- Channel attributes
    commission_rate DECIMAL(5,4),          -- 0.0000 to 1.0000
    cost_per_transaction DECIMAL(8,2),
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    launch_date DATE,
    
    -- Performance metrics (updated periodically)
    conversion_rate DECIMAL(5,4),
    average_transaction_value DECIMAL(10,2)
);

/*
 * CENTRAL FACT TABLE (Star Center)
 * Contains foreign keys to all dimensions and measurable facts
 */

CREATE TABLE FACT_ORDER_SALES (
    -- Foreign keys to dimensions (part of composite key)
    date_key INTEGER NOT NULL,
    product_key INTEGER NOT NULL,
    customer_key INTEGER NOT NULL,
    geography_key INTEGER NOT NULL,
    channel_key INTEGER NOT NULL,
    
    -- Degenerate dimensions (transaction-level details)
    order_id VARCHAR(20) NOT NULL,
    order_line_number INTEGER NOT NULL,
    
    -- Quantitative measures (facts)
    quantity_ordered INTEGER NOT NULL,
    quantity_shipped INTEGER,
    quantity_returned INTEGER DEFAULT 0,
    
    -- Financial measures
    unit_price DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    extended_price DECIMAL(12,2),          -- quantity * unit_price
    discounted_price DECIMAL(12,2),        -- extended_price - discount_amount
    
    unit_cost DECIMAL(10,2),
    extended_cost DECIMAL(12,2),           -- quantity * unit_cost
    
    gross_profit DECIMAL(12,2),            -- discounted_price - extended_cost
    
    -- Tax and shipping
    tax_amount DECIMAL(10,2) DEFAULT 0,
    shipping_cost DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(12,2),            -- discounted_price + tax + shipping
    
    -- Derived measures for analysis
    profit_margin DECIMAL(5,4),            -- gross_profit / discounted_price
    
    -- Transaction attributes
    order_date DATE NOT NULL,
    ship_date DATE,
    delivery_date DATE,
    
    -- Status indicators
    order_status VARCHAR(20),              -- Pending, Shipped, Delivered, Cancelled
    payment_method VARCHAR(30),
    
    -- Foreign key constraints
    CONSTRAINT fk_sales_date FOREIGN KEY (date_key) REFERENCES DIM_DATE(date_key),
    CONSTRAINT fk_sales_product FOREIGN KEY (product_key) REFERENCES DIM_PRODUCT(product_key),
    CONSTRAINT fk_sales_customer FOREIGN KEY (customer_key) REFERENCES DIM_CUSTOMER(customer_key),
    CONSTRAINT fk_sales_geography FOREIGN KEY (geography_key) REFERENCES DIM_GEOGRAPHY(geography_key),
    CONSTRAINT fk_sales_channel FOREIGN KEY (channel_key) REFERENCES DIM_SALES_CHANNEL(channel_key),
    
    -- Composite primary key
    PRIMARY KEY (date_key, product_key, customer_key, geography_key, channel_key, order_id, order_line_number)
);

/*
 * INDEXES FOR STAR SCHEMA OPTIMIZATION
 * Star schemas benefit from specific indexing strategies
 */

-- Fact table indexes (bitmap indexes work well for star schemas)
CREATE INDEX idx_fact_date ON FACT_ORDER_SALES(date_key);
CREATE INDEX idx_fact_product ON FACT_ORDER_SALES(product_key);
CREATE INDEX idx_fact_customer ON FACT_ORDER_SALES(customer_key);
CREATE INDEX idx_fact_geography ON FACT_ORDER_SALES(geography_key);
CREATE INDEX idx_fact_channel ON FACT_ORDER_SALES(channel_key);

-- Composite indexes for common query patterns
CREATE INDEX idx_fact_date_product ON FACT_ORDER_SALES(date_key, product_key);
CREATE INDEX idx_fact_customer_date ON FACT_ORDER_SALES(customer_key, date_key);

-- Dimension table indexes on natural keys
CREATE INDEX idx_product_id ON DIM_PRODUCT(product_id);
CREATE INDEX idx_customer_id ON DIM_CUSTOMER(customer_id);
CREATE INDEX idx_channel_id ON DIM_SALES_CHANNEL(channel_id);

/*
 * SAMPLE DATA POPULATION
 * Demonstrate star schema with realistic data
 */

-- Insert sample date dimension data
INSERT INTO DIM_DATE (date_key, full_date, day_of_week, day_name, day_of_month, day_of_year,
                     week_of_year, month_number, month_name, month_abbr, quarter_number, 
                     quarter_name, year_number, is_weekend, is_holiday, season)
VALUES 
(20240315, '2024-03-15', 5, 'Friday', 15, 75, 11, 3, 'March', 'Mar', 1, 'Q1', 2024, FALSE, FALSE, 'Spring'),
(20240316, '2024-03-16', 6, 'Saturday', 16, 76, 11, 3, 'March', 'Mar', 1, 'Q1', 2024, TRUE, FALSE, 'Spring'),
(20240317, '2024-03-17', 7, 'Sunday', 17, 77, 11, 3, 'March', 'Mar', 1, 'Q1', 2024, TRUE, FALSE, 'Spring');

-- Insert sample product dimension data
INSERT INTO DIM_PRODUCT (product_id, product_name, department_name, category_name, 
                        subcategory_name, brand_name, standard_cost, list_price, 
                        product_status, is_active)
VALUES 
('LAPTOP001', 'Gaming Laptop Pro', 'Electronics', 'Computers', 'Gaming Laptops', 'TechMax', 800.00, 1299.99, 'Active', TRUE),
('SHIRT001', 'Premium Dress Shirt', 'Clothing', 'Mens Apparel', 'Dress Shirts', 'StyleCorp', 25.00, 79.99, 'Active', TRUE),
('PHONE001', 'Smartphone Elite', 'Electronics', 'Mobile Devices', 'Smartphones', 'MobileTech', 400.00, 899.99, 'Active', TRUE);

-- Insert sample customer dimension data
INSERT INTO DIM_CUSTOMER (customer_id, customer_name, customer_type, customer_segment, 
                         city, state_province, country, registration_date, is_active)
VALUES 
('CUST001', 'John Doe', 'Individual', 'Premium', 'New York', 'NY', 'USA', '2023-01-15', TRUE),
('CUST002', 'Jane Smith', 'Individual', 'VIP', 'Los Angeles', 'CA', 'USA', '2022-06-20', TRUE),
('CUST003', 'TechCorp Inc', 'Business', 'Premium', 'Chicago', 'IL', 'USA', '2023-03-10', TRUE);

-- Insert sample geography dimension data
INSERT INTO DIM_GEOGRAPHY (country_code, country_name, region_name, state_province_name, 
                          city_name, market_segment, currency_code)
VALUES 
('USA', 'United States', 'North America', 'New York', 'New York', 'Developed', 'USD'),
('USA', 'United States', 'North America', 'California', 'Los Angeles', 'Developed', 'USD'),
('USA', 'United States', 'North America', 'Illinois', 'Chicago', 'Developed', 'USD');

-- Insert sample sales channel data
INSERT INTO DIM_SALES_CHANNEL (channel_id, channel_name, channel_type, channel_category, 
                              commission_rate, is_active)
VALUES 
('WEB', 'Website', 'Direct', 'Digital', 0.0000, TRUE),
('STORE', 'Retail Store', 'Direct', 'Physical', 0.0000, TRUE),
('PHONE', 'Phone Sales', 'Direct', 'Digital', 0.0200, TRUE);

-- Insert sample fact data
INSERT INTO FACT_ORDER_SALES (date_key, product_key, customer_key, geography_key, channel_key,
                             order_id, order_line_number, quantity_ordered, unit_price, 
                             discount_amount, extended_price, discounted_price, unit_cost, 
                             extended_cost, gross_profit, order_date, order_status)
VALUES 
(20240315, 1, 1, 1, 1, 'ORD001', 1, 1, 1299.99, 100.00, 1299.99, 1199.99, 800.00, 800.00, 399.99, '2024-03-15', 'Delivered'),
(20240316, 2, 2, 2, 2, 'ORD002', 1, 2, 79.99, 0.00, 159.98, 159.98, 50.00, 100.00, 59.98, '2024-03-16', 'Shipped'),
(20240317, 3, 3, 3, 1, 'ORD003', 1, 3, 899.99, 50.00, 2699.97, 2649.97, 1200.00, 3600.00, -950.03, '2024-03-17', 'Processing');

/*
 * STAR SCHEMA ANALYTICAL QUERIES
 * Demonstrate the power and simplicity of star schema queries
 */

-- Query 1: Sales summary by month and product category
SELECT 
    d.month_name,
    d.year_number,
    p.category_name,
    COUNT(*) as transaction_count,
    SUM(f.quantity_ordered) as total_quantity,
    SUM(f.discounted_price) as total_revenue,
    SUM(f.gross_profit) as total_profit,
    AVG(f.unit_price) as avg_unit_price
FROM FACT_ORDER_SALES f
    JOIN DIM_DATE d ON f.date_key = d.date_key
    JOIN DIM_PRODUCT p ON f.product_key = p.product_key
GROUP BY d.month_name, d.year_number, p.category_name
ORDER BY d.year_number, d.month_number, total_revenue DESC;

-- Query 2: Customer performance by segment and geography
SELECT 
    c.customer_segment,
    g.region_name,
    g.country_name,
    COUNT(DISTINCT c.customer_key) as customer_count,
    SUM(f.discounted_price) as total_revenue,
    AVG(f.discounted_price) as avg_order_value,
    SUM(f.gross_profit) as total_profit
FROM FACT_ORDER_SALES f
    JOIN DIM_CUSTOMER c ON f.customer_key = c.customer_key
    JOIN DIM_GEOGRAPHY g ON f.geography_key = g.geography_key
GROUP BY c.customer_segment, g.region_name, g.country_name
ORDER BY total_revenue DESC;

-- Query 3: Channel effectiveness analysis
SELECT 
    sc.channel_name,
    sc.channel_type,
    COUNT(*) as transaction_count,
    SUM(f.discounted_price) as total_revenue,
    AVG(f.discounted_price) as avg_transaction_value,
    SUM(f.gross_profit) as total_profit,
    (SUM(f.gross_profit) / SUM(f.discounted_price)) * 100 as profit_margin_pct
FROM FACT_ORDER_SALES f
    JOIN DIM_SALES_CHANNEL sc ON f.channel_key = sc.channel_key
GROUP BY sc.channel_name, sc.channel_type
ORDER BY total_revenue DESC;

-- Query 4: Time-based trend analysis
SELECT 
    d.quarter_name,
    d.year_number,
    COUNT(*) as order_count,
    SUM(f.quantity_ordered) as total_units_sold,
    SUM(f.discounted_price) as quarterly_revenue,
    SUM(f.gross_profit) as quarterly_profit
FROM FACT_ORDER_SALES f
    JOIN DIM_DATE d ON f.date_key = d.date_key
GROUP BY d.quarter_name, d.year_number
ORDER BY d.year_number, d.quarter_number;

/*
 * STAR SCHEMA BENEFITS DEMONSTRATED:
 * 
 * 1. Simple Joins: Only need to join fact table to relevant dimensions
 * 2. Query Performance: Fewer joins mean faster query execution
 * 3. Business Intuitive: Structure matches how business users think
 * 4. Denormalized Dimensions: All hierarchy levels available in single table
 * 5. Flexible Analysis: Easy to slice and dice data by any dimension
 * 6. Tool Compatibility: Works well with OLAP and BI tools
 */
