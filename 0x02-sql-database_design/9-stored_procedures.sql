-- 9-stored_procedures.sql: Stored Procedure Examples (PostgreSQL syntax)

-- Stored procedures encapsulate business logic

-- Simple procedure to add a user
CREATE OR REPLACE PROCEDURE add_user(email TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO users (email) VALUES (email);
END;
$$;

-- Call the procedure
CALL add_user('newuser@example.com');

-- Complex example with error handling
CREATE OR REPLACE PROCEDURE transfer_balance(
    from_account INT,
    to_account INT,
    amount NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF amount <= 0 THEN
        RAISE EXCEPTION 'Amount must be positive';
    END IF;

    UPDATE accounts SET balance = balance - amount WHERE account_id = from_account;
    UPDATE accounts SET balance = balance + amount WHERE account_id = to_account;
END;
$$;
