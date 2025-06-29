/*
  Filename: 1-oracle_plsql.sql
  Description: Introduction to PL/SQL scripting in Oracle
  Author: Alpha0-1
*/

-- Step 1: Create a table
CREATE TABLE employees (
    id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50),
    last_name VARCHAR2(50),
    salary NUMBER(10, 2)
);

-- Step 2: Insert sample data
INSERT INTO employees VALUES
(1, 'John', 'Doe', 50000.00),
(2, 'Jane', 'Smith', 65000.00);

-- Step 3: Basic PL/SQL block
DECLARE
    v_total_salary NUMBER;
BEGIN
    SELECT SUM(salary) INTO v_total_salary FROM employees;
    DBMS_OUTPUT.PUT_LINE('Total Salary: ' || v_total_salary);
END;
/

-- Step 4: PL/SQL procedure
CREATE OR REPLACE PROCEDURE get_employees AS
BEGIN
    FOR emp_record IN (SELECT * FROM employees) LOOP
        DBMS_OUTPUT.PUT_LINE('Employee: ' || emp_record.first_name || ' ' || emp_record.last_name);
    END LOOP;
END;
/

-- Step 5: Execute the procedure
BEGIN
    get_employees;
END;
/

-- Step 6: Parameterized procedure
CREATE OR REPLACE PROCEDURE add_employee (
    p_first_name VARCHAR2,
    p_last_name VARCHAR2,
    p_salary NUMBER
) AS
BEGIN
    INSERT INTO employees (id, first_name, last_name, salary)
    VALUES (employees_seq.NEXTVAL, p_first_name, p_last_name, p_salary);
    COMMIT;
END;
/

-- Step 7: Execute the add employee procedure
BEGIN
    add_employee('Bob', 'Johnson', 55000.00);
END;
/

/*
  Exercise:
  1. Create a PL/SQL function to calculate total salary
  2. Implement exception handling in PL/SQL
  3. Practice using cursors for record processing
*/

-- Cleanup
-- DROP TABLE employees;
-- DROP SEQUENCE employees_seq;
