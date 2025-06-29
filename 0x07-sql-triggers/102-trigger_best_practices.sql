-- File: 102-trigger_best_practices.sql
-- Description: Best practices for writing clean and maintainable triggers

--  DO:
-- - Keep logic simple
-- - Document clearly
-- - Handle errors gracefully

--  DON'T:
-- - Perform heavy computations
-- - Nest multiple triggers unnecessarily
-- - Modify unrelated tables without caution

-- Good example
CREATE OR REPLACE FUNCTION update_modified_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Bad example
CREATE OR REPLACE FUNCTION bad_trigger()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM some_complex_function();
    INSERT INTO unrelated_table SELECT * FROM big_table;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recommendation: Prefer constraints and application logic over triggers when possible
