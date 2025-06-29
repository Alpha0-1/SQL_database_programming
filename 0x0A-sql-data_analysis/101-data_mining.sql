-- 101-data_mining.sql
-- Extract insights through pattern recognition and aggregation

-- Example: Products frequently bought together
SELECT
    s1.product_id AS product_a,
    s2.product_id AS product_b,
    COUNT(*) AS co_occurrence_count
FROM sales s1
JOIN sales s2 ON s1.sale_id = s2.sale_id AND s1.product_id < s2.product_id
GROUP BY s1.product_id, s2.product_id
ORDER BY co_occurrence_count DESC;
