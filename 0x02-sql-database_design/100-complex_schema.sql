-- 100-complex_schema.sql: Example of a Multi-table Schema

-- Includes Users, Posts, Comments, Tags, and Relationships

CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS posts (
    post_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    title TEXT,
    content TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tags (
    tag_id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS post_tags (
    post_id INT REFERENCES posts(post_id),
    tag_id INT REFERENCES tags(tag_id),
    PRIMARY KEY (post_id, tag_id)
);

CREATE TABLE IF NOT EXISTS comments (
    comment_id SERIAL PRIMARY KEY,
    post_id INT REFERENCES posts(post_id),
    user_id INT REFERENCES users(user_id),
    text TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Sample inserts
INSERT INTO users (username) VALUES ('alice');
INSERT INTO posts (user_id, title, content) VALUES (1, 'Intro to DB Design', '...');
INSERT INTO tags (name) VALUES ('SQL'), ('Database');
INSERT INTO post_tags VALUES (1, 1), (1, 2);
