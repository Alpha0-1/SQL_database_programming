-- File: 11-validation_triggers.sql
-- Description: Using triggers for data validation

-- Enforce minimum age during user creation
CREATE OR REPLACE FUNCTION validate_user_age()
RETURNS TRIGGER AS $$
DECLARE
    user_birthdate DATE;
BEGIN
    SELECT birthdate INTO user_birthdate
    FROM users
    WHERE id = NEW.id;

    IF EXTRACT(YEAR FROM AGE(user_birthdate)) < 18 THEN
        RAISE EXCEPTION 'User must be at least 18 years old';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Example assumes a users table with birthdate field
ALTER TABLE users ADD COLUMN birthdate DATE;

-- Create the trigger
CREATE TRIGGER validate_user_age_before_insert
BEFORE INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION validate_user_age();

-- Test
INSERT INTO users (username, birthdate) VALUES ('younguser', '2010-01-01');
-- Should raise exception due to underage
