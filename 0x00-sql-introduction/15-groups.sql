-- Group by a column and count entries per group
-- Example: Count number of students per department

SELECT department, COUNT(*) AS num_students
FROM employees
GROUP BY department;
