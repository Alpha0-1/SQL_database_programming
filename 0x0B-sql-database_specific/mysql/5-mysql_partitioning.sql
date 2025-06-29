-- MySQL Partitioning Example

-- Create a partitioned table by RANGE
CREATE TABLE logs (
    log_id INT,
    log_date DATE
)
PARTITION BY RANGE (YEAR(log_date)) (
    PARTITION p2020 VALUES LESS THAN (2021),
    PARTITION p2021 VALUES LESS THAN (2022),
    PARTITION p2022 VALUES LESS THAN (2023)
);

-- Insert test data
INSERT INTO logs VALUES
    (1, '2020-05-01'),
    (2, '2021-06-12'),
    (3, '2022-08-22');

-- Query specific partitions
SELECT * FROM logs PARTITION (p2021);
