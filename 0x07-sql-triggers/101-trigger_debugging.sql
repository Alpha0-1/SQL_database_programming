-- File: 101-trigger_debugging.sql
-- Description: Debugging techniques for triggers

-- Enable debug messages
CREATE OR REPLACE FUNCTION debug_trigger()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Trigger fired: %', TG_NAME;
    RAISE NOTICE 'Operation: %', TG_OP;
    RAISE NOTICE 'Table: %', TG_TABLE_NAME;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Test the trigger
CREATE TRIGGER test_debug
BEFORE INSERT ON employees
FOR EACH ROW
EXECUTE FUNCTION debug_trigger();

-- Insert to see debug output
INSERT INTO employees (name, salary) VALUES ('Debug User', 50000);
-- Look for NOTICE lines in output
