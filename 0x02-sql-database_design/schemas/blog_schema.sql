-- schemas/blog_schema.sql: Blogging Platform Schema

CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS posts (
    post_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    title TEXT,
    content TEXT,
    published BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS comments (
    comment_id SERIAL PRIMARY KEY,
    post_id INT REFERENCES posts(post_id),
    user_id INT REFERENCES users(user_id),
    text TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
