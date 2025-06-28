-- 4-entity_relationship.sql: Implementing ER Diagram Concepts

-- Entities: Tables
-- Relationships: Foreign keys

-- One-to-One Relationship
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS profiles (
    profile_id SERIAL PRIMARY KEY,
    user_id INT UNIQUE REFERENCES users(user_id),
    bio TEXT
);

-- One-to-Many Relationship
CREATE TABLE IF NOT EXISTS authors (
    author_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS books (
    book_id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INT REFERENCES authors(author_id)
);

-- Many-to-Many Relationship
CREATE TABLE IF NOT EXISTS students (
    student_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS courses (
    course_id SERIAL PRIMARY KEY,
    title TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS enrollments (
    student_id INT REFERENCES students(student_id),
    course_id INT REFERENCES courses(course_id),
    PRIMARY KEY (student_id, course_id)
);

-- Sample insertions
INSERT INTO authors (name) VALUES ('J.K. Rowling');
INSERT INTO books (title, author_id) VALUES ('Harry Potter', 1);

INSERT INTO students (name) VALUES ('Alice');
INSERT INTO courses (title) VALUES ('Math');
INSERT INTO enrollments (student_id, course_id) VALUES (1, 1);
