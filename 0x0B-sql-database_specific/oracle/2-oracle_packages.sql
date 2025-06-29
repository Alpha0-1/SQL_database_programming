/*
  Filename: 2-oracle_packages.sql
  Description: Creating and using Oracle packages
  Author: Alpha0-1
*/

-- Step 1: Create a package specification
CREATE OR REPLACE PACKAGE employee_pkg AS
    PROCEDURE add_employee (
        p_first_name VARCHAR2,
        p_last_name VARCHAR2,
        p_salary NUMBER
    );
    FUNCTION get_total_salary RETURN NUMBER;
END employee_pkg;
/

-- Step 2: Create the package body
CREATE OR REPLACE PACKAGE BODY employee_pkg AS
    PROCEDURE add_employee (
        p_first_name VARCHAR2,
        p_last_name VARCHAR2,
        p_salary NUMBER
    ) AS
    BEGIN
        INSERT INTO employees (id, first_name, last_name, salary)
        VALUES (employees_seq.NEXTVAL, p_first_name, p_last_name, p_salary);
        COMMIT;
    END add_employee;

    FUNCTION get_total_salary RETURN NUMBER AS
        v_total NUMBER;
    BEGIN
        SELECT SUM(salary) INTO v_total FROM employees;
        RETURN v_total;
    END get_total_salary;
END employee_pkg;
/

-- Step 3: Execute package procedures
BEGIN
    employee_pkg.add_employee('John', 'Doe', 50000.00);
    employee_pkg.add_employee('Jane', 'Smith', 65000.00);
    
    DBMS_OUTPUT.PUT_LINE('Total Salary: ' || employee_pkg.get_total_salary());
END;
/

/*
  Exercise:
  1. Add a procedure to update employee salary in the package
  2. Implement exception handling within the package
  3. Practice using package variables (global variables)
*/

-- Cleanup
-- DROP TABLE employees;
-- DROP SEQUENCE employees_seq;
-- DROP PACKAGE employee_pkg;
