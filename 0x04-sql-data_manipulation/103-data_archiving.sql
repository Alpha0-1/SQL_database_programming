-- Archive old records to a separate table

-- Create archive table
CREATE TABLE IF NOT EXISTS orders_archive AS
SELECT * FROM orders WHERE FALSE;

-- Move orders older than 1 year to archive
INSERT INTO orders_archive
SELECT * FROM orders
WHERE order_date < CURRENT_DATE - INTERVAL '1 year';

-- Delete archived records from main table
DELETE FROM orders
WHERE order_date < CURRENT_DATE - INTERVAL '1 year';

SELECT 'Old orders archived successfully' AS status;
