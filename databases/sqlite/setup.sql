-- SQLite Initialization Script

-- Create a students table
CREATE TABLE IF NOT EXISTS students (
    student_id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    date_of_birth TEXT
);

-- Insert sample data
INSERT INTO students (first_name, last_name, email, date_of_birth)
VALUES
    ('Eve', 'Martinez', 'eve@example.com', '2003-04-18'),
    ('Frank', 'Lee', 'frank@example.com', '2000-11-30');
