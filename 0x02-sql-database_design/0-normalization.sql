-- This script demonstrates normalization concepts using an example of a student-course database

-- Unnormalized table example
CREATE TABLE student_courses_raw (
	    student_id INT,
	    student_name VARCHAR(100),
	    course1 VARCHAR(100),
	    course2 VARCHAR(100),
	    course3 VARCHAR(100)
);

-- Inserting sample data
INSERT INTO student_courses_raw VALUES (1, 'Alice', 'Math', 'English', 'Physics');
INSERT INTO student_courses_raw VALUES (2, 'Bob', 'Biology', 'Chemistry', NULL);

-- Normalized into 1NF (atomic values only)
CREATE TABLE students (
	    student_id INT PRIMARY KEY,
	    student_name VARCHAR(100)
);

CREATE TABLE courses (
	    course_id INT PRIMARY KEY AUTO_INCREMENT,
	    student_id INT,
	    course_name VARCHAR(100),
	    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

INSERT INTO students VALUES (1, 'Alice'), (2, 'Bob');
INSERT INTO courses (student_id, course_name) VALUES
(1, 'Math'), (1, 'English'), (1, 'Physics'),
(2, 'Biology'), (2, 'Chemistry');

