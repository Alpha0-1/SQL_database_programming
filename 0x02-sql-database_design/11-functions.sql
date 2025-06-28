-- 11-functions.sql: User-defined Functions

-- Functions return a value and can be reused across queries

-- Simple function to get total orders
CREATE OR REPLACE FUNCTION get_total_orders() RETURNS INT AS $$
DECLARE
    total INT;
BEGIN
    SELECT COUNT(*) INTO total FROM orders;
    RETURN total;
END;
$$ LANGUAGE plpgsql;

-- Use the function
SELECT get_total_orders();

-- Function with parameters
CREATE OR REPLACE FUNCTION get_orders_by_customer(cust_id INT)
RETURNS TABLE(order_id INT, order_date DATE) AS $$
BEGIN
    RETURN QUERY
    SELECT o.order_id, o.order_date
    FROM orders o
    WHERE o.customer_id = cust_id;
END;
$$ LANGUAGE plpgsql;

-- Use parameterized function
SELECT * FROM get_orders_by_customer(1);
