/*
 * File: 2-snowflake_schema.sql
 * Author: Alpha0-1
 * Description: Snowflake Schema implementation and design patterns
 * 
 * Snowflake Schema is a normalized dimensional modeling approach where:
 * - Dimension tables are normalized into multiple related tables
 * - Reduces data redundancy and storage space
 * - More complex than star schema but saves storage
 * - Resembles a snowflake when visualized (branching structure)
 * 
 * When to use Snowflake Schema:
 * - Storage cost is a primary concern
 * - Dimension hierarchies are deep and complex
 * - Data consistency is critical
 * - ETL processes can handle more complex joins
 * 
 * Trade-offs:
 * - Pros: Reduced storage, better data integrity, easier maintenance
 * - Cons: More complex queries, slower performance, harder for business users
 */

-- Drop existing tables if they exist (for clean implementation)
DROP TABLE IF EXISTS FACT_SALES CASCADE;
DROP TABLE IF EXISTS DIM_DATE CASCADE;
DROP TABLE IF EXISTS DIM_PRODUCT CASCADE;
DROP TABLE IF EXISTS DIM_PRODUCT_CATEGORY CASCADE;
DROP TABLE IF EXISTS DIM_PRODUCT_SUBCATEGORY CASCADE;
DROP TABLE IF EXISTS DIM_BRAND CASCADE;
DROP TABLE IF EXISTS DIM_SUPPLIER CASCADE;
DROP TABLE IF EXISTS DIM_CUSTOMER CASCADE;
DROP TABLE IF EXISTS DIM_CUSTOMER_TYPE CASCADE;
DROP TABLE IF EXISTS DIM_GEOGRAPHY CASCADE;
DROP TABLE IF EXISTS DIM_COUNTRY CASCADE;
DROP TABLE IF EXISTS DIM_REGION CASCADE;
DROP TABLE IF EXISTS DIM_STATE CASCADE;
DROP TABLE IF EXISTS DIM_CITY CASCADE;

/*
 * SNOWFLAKE SCHEMA IMPLEMENTATION: RETAIL ANALYTICS
 * 
 * Business Case: Large retail chain needs detailed analytics while
 * minimizing storage costs and maintaining data consistency across
 * complex hierarchical dimensions.
 */

/*
 * NORMALIZED DIMENSION TABLES (Snowflake Arms)
 * Each hierarchy level is stored in separate, normalized tables
 */

-- Geographic Hierarchy (4 levels normalized)

-- Level 1: Region (Highest level)
CREATE TABLE DIM_REGION (
    region_key SERIAL PRIMARY KEY,
    region_code VARCHAR(10) NOT NULL UNIQUE,
    region_name VARCHAR(50) NOT NULL,
    region_description TEXT,
    continent VARCHAR(30),
    created_date DATE DEFAULT CURRENT_DATE,
    is_active BOOLEAN DEFAULT TRUE
);

-- Level 2: Country
CREATE TABLE DIM_COUNTRY (
    country_key SERIAL PRIMARY KEY,
    country_code VARCHAR(3) NOT NULL UNIQUE,
    country_name VARCHAR(50) NOT NULL,
    currency_code VARCHAR(3),
    currency_name VARCHAR(30),
    population BIGINT,
    gdp_per_capita DECIMAL(12,2),
    time_zone VARCHAR(50),
    
    -- Foreign key to parent level
    region_key INTEGER NOT NULL,
    FOREIGN KEY (region_key) REFERENCES DIM_REGION(region_key)
);

-- Level 3: State/Province
CREATE TABLE DIM_STATE (
    state_key SERIAL PRIMARY KEY,
    state_code VARCHAR(10) NOT NULL,
    state_name VARCHAR(50) NOT NULL,
    population INTEGER,
    area_sq_km DECIMAL(12,2),
    
    -- Foreign key to parent level
    country_key INTEGER NOT NULL,
    FOREIGN KEY (country_key) REFERENCES DIM_COUNTRY(country_key),
    
    -- Unique constraint on state within country
    UNIQUE(country_key, state_code)
);

-- Level 4: City (Lowest level)
CREATE TABLE DIM_CITY (
    city_key SERIAL PRIMARY KEY,
    city_name VARCHAR(50) NOT NULL,
    postal_code VARCHAR(20),
    population INTEGER,
    area_sq_km DECIMAL(10,2),
    
    -- Foreign key to parent level
    state_key INTEGER NOT NULL,
    FOREIGN KEY (state_key) REFERENCES DIM_STATE(state_key)
);

-- Main Geography Dimension (references the hierarchy)
CREATE TABLE DIM_GEOGRAPHY (
    geography_key SERIAL PRIMARY KEY,
    address_line1 VARCHAR(100),
    address_line2 VARCHAR(100),
    
    -- Foreign keys to normalized hierarchy
    city_key INTEGER NOT NULL,
    state_key INTEGER NOT NULL,
    country_key INTEGER NOT NULL,
    region_key INTEGER NOT NULL,
    
    FOREIGN KEY (city_key) REFERENCES DIM_CITY(city_key),
    FOREIGN KEY (state_key) REFERENCES DIM_STATE(state_key),
    FOREIGN KEY (country_key) REFERENCES DIM_COUNTRY(country_key),
    FOREIGN KEY (region_key) REFERENCES DIM_REGION(region_key)
);

-- Product Hierarchy (4 levels normalized)

-- Level 1: Supplier
CREATE TABLE DIM_SUPPLIER (
    supplier_key SERIAL PRIMARY KEY,
    supplier_code VARCHAR(20) NOT NULL UNIQUE,
    supplier_name VARCHAR(100) NOT NULL,
    contact_name VARCHAR(100),
    contact_email VARCHAR(100),
    contact_phone VARCHAR(20),
    
    -- Supplier geography (could reference DIM_GEOGRAPHY)
    supplier_city VARCHAR(50),
    supplier_country VARCHAR(50),
    
    -- Business attributes
    credit_rating VARCHAR(10),
    preferred_supplier BOOLEAN DEFAULT FALSE,
    contract_start_date DATE,
    contract_end_date DATE
);

-- Level 2: Brand
CREATE TABLE DIM_BRAND (
    brand_key SERIAL PRIMARY KEY,
    brand_code VARCHAR(20) NOT NULL UNIQUE,
    brand_name VARCHAR(50) NOT NULL,
    brand_description TEXT,
    parent_company VARCHAR(100),
    brand_positioning VARCHAR(50),  -- Luxury, Premium, Standard, Budget
    launch_date DATE,
    
    -- Foreign key to supplier
    supplier_key INTEGER NOT NULL,
    FOREIGN KEY (supplier_key) REFERENCES DIM_SUPPLIER(supplier_key)
);

-- Level 3: Product Category
CREATE TABLE DIM_PRODUCT_CATEGORY (
    category_key SERIAL PRIMARY KEY,
    category_code VARCHAR(20) NOT NULL UNIQUE,
    category_name VARCHAR(50) NOT NULL,
    category_description TEXT,
    
    -- Category attributes
    target_margin DECIMAL(5,4),
    seasonal_factor DECIMAL(5,4),
    is_promotional BOOLEAN DEFAULT FALSE
);

-- Level 4: Product Subcategory
CREATE TABLE DIM_PRODUCT_SUBCATEGORY (
    subcategory_key SERIAL PRIMARY KEY,
    subcategory_code VARCHAR(20) NOT NULL,
    subcategory_name VARCHAR(50) NOT NULL,
    subcategory_description TEXT,
    
    -- Foreign key to parent category
    category_key INTEGER NOT NULL,
    FOREIGN KEY (category_key) REFERENCES DIM_PRODUCT_CATEGORY(category_key),
    
    UNIQUE(category_key, subcategory_code)
);

-- Main Product Dimension (references the hierarchy)
CREATE TABLE DIM_PRODUCT (
    product_key SERIAL PRIMARY KEY,
    product_code VARCHAR(30) NOT NULL UNIQUE,
    product_name VARCHAR(100) NOT NULL,
    product_description TEXT,
    
    -- Product specifications
    color VARCHAR(30),
    size VARCHAR(20),
    weight_kg DECIMAL(8,3),
    
    -- Financial attributes
    standard_cost DECIMAL(10,2),
    list_price DECIMAL(10,2),
    
    -- Foreign keys to normalized hierarchy
    subcategory_key INTEGER NOT NULL,
    category_key INTEGER NOT NULL,
    brand_key INTEGER NOT NULL,
    supplier_key INTEGER NOT NULL,
    
    -- Product lifecycle
    launch_date DATE,
    discontinue_date DATE,
    product_status VARCHAR(20) DEFAULT 'Active',
    
    FOREIGN KEY (subcategory_key) REFERENCES DIM_PRODUCT_SUBCATEGORY(subcategory_key),
    FOREIGN KEY (category_key) REFERENCES DIM_PRODUCT_CATEGORY(category_key),
    FOREIGN KEY (brand_key) REFERENCES DIM_BRAND(brand_key),
    FOREIGN KEY (supplier_key) REFERENCES DIM_SUPPLIER(supplier_key)
);

-- Customer Hierarchy (2 levels normalized)

-- Level 1: Customer Type
CREATE TABLE DIM_CUSTOMER_TYPE (
    customer_type_key SERIAL PRIMARY KEY,
    type_code VARCHAR(10) NOT NULL UNIQUE,
    type_name VARCHAR(30) NOT NULL,
    type_description TEXT,
    
    -- Type attributes
    discount_rate DECIMAL(5,4) DEFAULT 0.0000,
    credit_limit DECIMAL(12,2),
    payment_terms_days INTEGER DEFAULT 30,
    requires_approval BOOLEAN DEFAULT FALSE
);

-- Main Customer Dimension
CREATE TABLE DIM_CUSTOMER (
    customer_key SERIAL PRIMARY KEY,
    customer_code VARCHAR(20) NOT NULL UNIQUE,
    customer_name VARCHAR(100) NOT NULL,
    
    -- Contact information
    email VARCHAR(100),
    phone VARCHAR(20),
    
    -- Customer segmentation
    customer_segment VARCHAR(30),
    credit_rating VARCHAR(10),
    
    -- Important dates
    registration_date DATE,
    first_purchase_date DATE,
    last_purchase_date DATE,
    
    -- Calculated metrics (updated via ETL)
    lifetime_value DECIMAL(12,2),
    total_orders INTEGER DEFAULT 0,
    average_order_value DECIMAL(10,2),
    
    -- Foreign keys to normalized hierarchy
    customer_type_key INTEGER NOT NULL,
    geography_key INTEGER NOT NULL,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    FOREIGN KEY (customer_type_key) REFERENCES DIM_CUSTOMER_TYPE(customer_type_key),
    FOREIGN KEY (geography_key) REFERENCES DIM_GEOGRAPHY(geography_key)
);

-- Date Dimension (kept simple - could be normalized further)
CREATE TABLE DIM_DATE (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    
    -- Date attributes
    day_of_week INTEGER,
    day_name VARCHAR(10),
    day_of_month INTEGER,
    day_of_year INTEGER,
    
    week_of_year INTEGER,
    month_number INTEGER,
    month_name VARCHAR(10),
    quarter_number INTEGER,
    year_number INTEGER,
    
    -- Business calendar
    is_weekend BOOLEAN,
    is_holiday BOOLEAN,
    holiday_name VARCHAR(50),
    
    fiscal_year INTEGER,
    fiscal_quarter INTEGER,
    fiscal_month INTEGER
);

/*
 * CENTRAL FACT TABLE
 * References all dimension tables through foreign keys
 */

CREATE TABLE FACT_SALES (
    -- Dimension foreign keys
    date_key INTEGER NOT NULL,
    product_key INTEGER NOT NULL,
    customer_key INTEGER NOT NULL,
    geography_key INTEGER NOT NULL,
    
    -- Degenerate dimensions
    order_number VARCHAR(20) NOT NULL,
    invoice_number VARCHAR(20),
    line_item_number INTEGER NOT NULL,
    
    -- Quantitative measures
    quantity_ordered INTEGER NOT NULL,
    quantity_shipped INTEGER,
    quantity_returned INTEGER DEFAULT 0,
    
    -- Financial measures
    unit_price DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    extended_amount DECIMAL(12,2),
    tax_amount DECIMAL(10,2) DEFAULT 0,
    shipping_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(12,2),
    
    unit_cost DECIMAL(10,2),
    total_cost DECIMAL(12,2),
    gross_profit DECIMAL(12,2),
    
    -- Transaction details
    order_date DATE NOT NULL,
    ship_date DATE,
    required_date DATE,
    
    -- Status
    order_status VARCHAR(20),
    payment_method VARCHAR(30),
    
    -- Foreign key constraints
    FOREIGN KEY (date_key) REFERENCES DIM_DATE(date_key),
    FOREIGN KEY (product_key) REFERENCES DIM_PRODUCT(product_key),
    FOREIGN KEY (customer_key) REFERENCES DIM_CUSTOMER(customer_key),
    FOREIGN KEY (geography_key) REFERENCES DIM_GEOGRAPHY(geography_key),
    
    -- Composite primary key
    PRIMARY KEY (date_key, product_key, customer_key, geography_key, order_number, line_item_number)
);

/*
 * INDEXES FOR SNOWFLAKE SCHEMA
 * More indexes needed due to complex joins
 */

-- Fact table indexes
CREATE INDEX idx_sales_date ON FACT_SALES(date_key);
CREATE INDEX idx_sales_product ON FACT_SALES(product_key);
CREATE INDEX idx_sales_customer ON FACT_SALES(customer_key);
CREATE INDEX idx_sales_geography ON FACT_SALES(geography_key);

-- Dimension hierarchy indexes
CREATE INDEX idx_geography_city ON DIM_GEOGRAPHY(city_key);
CREATE INDEX idx_geography_state ON DIM_GEOGRAPHY(state_key);
CREATE INDEX idx_geography_country ON DIM_GEOGRAPHY(country_key);
CREATE INDEX idx_geography_region ON DIM_GEOGRAPHY(region_key);

CREATE INDEX idx_product_subcategory ON DIM_PRODUCT(subcategory_key);
CREATE INDEX idx_product_category ON DIM_PRODUCT(category_key);
CREATE INDEX idx_product_brand ON DIM_PRODUCT(brand_key);
CREATE INDEX idx_product_supplier ON DIM_PRODUCT(supplier_key);

CREATE INDEX idx_customer_type ON DIM_CUSTOMER(customer_type_key);
CREATE INDEX idx_customer_geography ON DIM_CUSTOMER(geography_key);

-- Parent-child relationship indexes
CREATE INDEX idx_country_region ON DIM_COUNTRY(region_key);
CREATE INDEX idx_state_country ON DIM_STATE(country_key);
CREATE INDEX idx_city_state ON DIM_CITY(state_key);
CREATE INDEX idx_subcategory_category ON DIM_PRODUCT_SUBCATEGORY(category_key);
CREATE INDEX idx_brand_supplier ON DIM_BRAND(supplier_key);

/*
 * SAMPLE DATA POPULATION
 */

-- Insert sample regional hierarchy
INSERT INTO DIM_REGION (region_code, region_name, continent) VALUES
('NORAM', 'North America', 'North America'),
('EMEA', 'Europe Middle East Africa', 'Multiple'),
('APAC', 'Asia Pacific', 'Asia');

INSERT INTO DIM_COUNTRY (country_code, country_name, currency_code, region_key) VALUES
('USA', 'United States', 'USD', 1),
('CAN', 'Canada', 'CAD', 1),
('GBR', 'United Kingdom', 'GBP', 2);

INSERT INTO DIM_STATE (state_code, state_name, country_key) VALUES
('NY', 'New York', 1),
('CA', 'California', 1),
('ON', 'Ontario', 2);

INSERT INTO DIM_CITY (city_name, postal_code, state_key) VALUES
('New York City', '10001', 1),
('Los Angeles', '90210', 2),
('Toronto', 'M5V', 3);

INSERT INTO DIM_GEOGRAPHY (city_key, state_key, country_key, region_key) VALUES
(1, 1, 1, 1),
(2, 2, 1, 1),
(3, 3, 2, 1);

-- Insert product hierarchy
INSERT INTO DIM_PRODUCT_CATEGORY (category_code, category_name) VALUES
('ELEC', 'Electronics'),
('CLTH', 'Clothing'),
('HOME', 'Home & Garden');

INSERT INTO DIM_PRODUCT_SUBCATEGORY (subcategory_code, subcategory_name, category_key) VALUES
('COMP', 'Computers', 1),
('PHON', 'Phones', 1),
('SHRT', 'Shirts', 2);

INSERT INTO DIM_SUPPLIER (supplier_code, supplier_name, supplier_country) VALUES
('TECH01', 'TechSupplier Inc', 'USA'),
('CLTH01', 'ClothingMaker Ltd', 'Bangladesh'),
('ELEC01', 'ElectronicsCorp', 'China');

INSERT INTO DIM_BRAND (brand_code, brand_name, supplier_key) VALUES
('APPLE', 'Apple', 1),
('NIKE', 'Nike', 2),
('SAMSG', 'Samsung', 3);

INSERT INTO DIM_PRODUCT (product_code, product_name, standard_cost, list_price, 
                        subcategory_key, category_key, brand_key, supplier_key) VALUES
('LAPTOP01', 'MacBook Pro', 1200.00, 1999.99, 1, 1, 1, 1),
('PHONE01', 'Galaxy S24', 400.00, 899.99, 2, 1, 3, 3),
('SHIRT01', 'Nike Polo Shirt', 15.00, 49.99, 3, 2, 2, 2);

-- Insert customer hierarchy
INSERT INTO DIM_CUSTOMER_TYPE (type_code, type_name, discount_rate) VALUES
('IND', 'Individual', 0.0000),
('BUS', 'Business', 0.0500),
('VIP', 'VIP Customer', 0.1000);

INSERT INTO DIM_CUSTOMER (customer_code, customer_name, customer_segment, 
                         customer_type_key, geography_key) VALUES
('CUST001', 'John Smith', 'Premium', 1, 1),
('CUST002', 'ABC Corporation', 'Enterprise', 2, 2),
('CUST003', 'Jane Doe', 'VIP', 3, 3);

-- Insert date data
INSERT INTO DIM_DATE (date_key, full_date, day_of_week, day_name, month_number, 
                     month_name, quarter_number, year_number, is_weekend) VALUES
(20240320, '2024-03-20', 3, 'Wednesday', 3, 'March', 1, 2024, FALSE),
(20240321, '2024-03-21', 4, 'Thursday', 3, 'March', 1, 2024, FALSE),
(20240322, '2024-03-22', 5, 'Friday', 3, 'March', 1, 2024, FALSE);

-- Insert fact data
INSERT INTO FACT_SALES (date_key, product_key, customer_key, geography_key, 
                       order_number, line_item_number, quantity_ordered, 
                       unit_price, extended_amount, unit_cost, total_cost, 
                       gross_profit, order_date) VALUES
(20240320, 1, 1, 1, 'ORD001', 1, 1, 1999.99, 1999.99, 1200.00, 1200.00, 799.99, '2024-03-20'),
(20240321, 2, 2, 2, 'ORD002', 1, 2, 899.99, 1799.98, 800.00, 1600.00, 199.98, '2024-03-21'),
(20240322, 3, 3, 3, 'ORD003', 1, 3, 49.99, 149.97, 45.00, 135.00, 14.97, '2024-03-22');

/*
 * SNOWFLAKE SCHEMA ANALYTICAL QUERIES
 * Note: More complex joins required due to normalization
 */

-- Query 1: Sales by geographic hierarchy (requires multiple joins)
SELECT 
    r.region_name,
    c.country_name,
    s.state_name,
    ct.city_name,
    COUNT(*) as transaction_count,
    SUM(f.extended_amount) as total_sales,
    AVG(f.extended_amount) as avg_transaction_value
FROM FACT_SALES f
    JOIN DIM_GEOGRAPHY g ON f.geography_key = g.geography_key
    JOIN DIM_CITY ct ON g.city_key = ct.city_key
    JOIN DIM_STATE s ON g.state_key = s.state_key
    JOIN DIM_COUNTRY c ON g.country_key = c.country_key
    JOIN DIM_REGION r ON g.region_key = r.region_key
GROUP BY r.region_name, c.country_name, s.state_name, ct.city_name
ORDER BY total_sales DESC;

-- Query 2: Product hierarchy analysis (multiple product joins)
SELECT 
    sup.supplier_name,
    b.brand_name,
    pc.category_name,
    psc.subcategory_name,
    COUNT(*) as product_count,
    SUM(f.quantity_ordered) as total_quantity,
    SUM(f.extended_amount) as total_revenue,
    SUM(f.gross_profit) as total_profit
FROM FACT_SALES f
    JOIN DIM_PRODUCT p ON f.product_key = p.product_key
    JOIN DIM_PRODUCT_SUBCATEGORY psc ON p.subcategory_key = psc.subcategory_key
    JOIN DIM_PRODUCT_CATEGORY pc ON p.category_key = pc.category_key
    JOIN DIM_BRAND b ON p.brand_key = b.brand_key
    JOIN DIM_SUPPLIER sup ON p.supplier_key = sup.supplier_key
GROUP BY sup.supplier_name, b.brand_name, pc.category_name, psc.subcategory_name
ORDER BY total_revenue DESC;

-- Query 3: Customer type analysis
SELECT 
    ct.type_name,
    cust.customer_segment,
    COUNT(DISTINCT cust.customer_key) as customer_count,
    SUM(f.extended_amount) as total_revenue,
    AVG(f.extended_amount) as avg_order_value,
    SUM(f.gross_profit) as total_profit
FROM FACT_SALES f
    JOIN DIM_CUSTOMER cust ON f.customer_key = cust.customer_key
    JOIN DIM_CUSTOMER_TYPE ct ON cust.customer_type_key = ct.customer_type_key
GROUP BY ct.type_name, cust.customer_segment
ORDER BY total_revenue DESC;

-- Query 4: Complete hierarchy drill-down (demonstrates complexity)
SELECT 
    -- Time hierarchy
    d.year_number,
    d.quarter_number,
    d.month_name,
    
    -- Geographic hierarchy
    r.region_name,
    c.country_name,
    
    -- Product hierarchy
    pc.category_name,
    b.brand_name,
    
    -- Customer hierarchy
    ct.type_name,
    
    -- Aggregated measures
    COUNT(*) as transaction_count,
    SUM(f.quantity_ordered) as total_quantity,
    SUM(f.extended_amount) as total_sales,
    SUM(f.gross_profit) as total_profit,
    AVG(f.extended_amount) as avg_transaction_value
FROM FACT_SALES f
    -- Date dimension (simple)
    JOIN DIM_DATE d ON f.date_key = d.date_key
    
    -- Geographic hierarchy joins
    JOIN DIM_GEOGRAPHY g ON f.geography_key = g.geography_key
    JOIN DIM_COUNTRY c ON g.country_key = c.country_key
    JOIN DIM_REGION r ON g.region_key = r.region_key
    
    -- Product hierarchy joins
    JOIN DIM_PRODUCT p ON f.product_key = p.product_key
    JOIN DIM_PRODUCT_CATEGORY pc ON p.category_key = pc.category_key
    JOIN DIM_BRAND b ON p.brand_key = b.brand_key
    
    -- Customer hierarchy joins
    JOIN DIM_CUSTOMER cust ON f.customer_key = cust.customer_key
    JOIN DIM_CUSTOMER_TYPE ct ON cust.customer_type_key = ct.customer_type_key
GROUP BY 
    d.year_number, d.quarter_number, d.month_name,
    r.region_name, c.country_name,
    pc.category_name, b.brand_name,
    ct.type_name
ORDER BY total_sales DESC;

/*
 * SNOWFLAKE SCHEMA CHARACTERISTICS DEMONSTRATED:
 * 
 * Advantages:
 * 1. Storage Efficiency: Eliminates redundant data in dimensions
 * 2. Data Integrity: Normalized structure reduces update anomalies
 * 3. Flexibility: Easy to add new hierarchy levels
 * 4. Maintenance: Changes to hierarchy attributes affect fewer records
 * 
 * Disadvantages:
 * 1. Query Complexity: Requires many joins for hierarchical analysis
 * 2. Performance Impact: More joins can slow query execution
 * 3. User Complexity: Harder for business users to understand and navigate
 * 4. ETL Complexity: More complex data loading and maintenance processes
 * 
 * Best Practices:
 * 1. Use when storage costs are critical
 * 2. Implement proper indexing strategy
 * 3. Consider creating views to simplify common queries
 * 4. Monitor query performance and optimize as needed
 */
