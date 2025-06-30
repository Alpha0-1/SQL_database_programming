-- PostgreSQL Initialization Script

-- Connect to default database (created via POSTGRES_DB env var)
\c school_db

-- Create a students table
CREATE TABLE IF NOT EXISTS students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    date_of_birth DATE
);

-- Insert sample data
INSERT INTO students (first_name, last_name, email, date_of_birth)
VALUES
    ('Charlie', 'Brown', 'charlie@example.com', '2001-01-10'),
    ('Dana', 'White', 'dana@example.com', '2002-09-05')
ON CONFLICT (student_id) DO NOTHING;
