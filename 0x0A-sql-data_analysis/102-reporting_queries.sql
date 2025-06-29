-- 102-reporting_queries.sql
-- Build complex reports combining multiple metrics

-- Example: Sales report by region and category
SELECT
    r.region_name,
    c.category_name,
    SUM(s.amount) AS total_sales,
    COUNT(DISTINCT s.customer_id) AS unique_customers,
    AVG(s.amount) AS avg_sale_value
FROM sales s
JOIN regions r ON s.region_id = r.region_id
JOIN categories c ON s.category_id = c.category_id
GROUP BY r.region_name, c.category_name
ORDER BY total_sales DESC;
