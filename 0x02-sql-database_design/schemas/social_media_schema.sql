-- schemas/social_media_schema.sql: Social Media Schema

CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS posts (
    post_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    content TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS likes (
    post_id INT REFERENCES posts(post_id),
    user_id INT REFERENCES users(user_id),
    PRIMARY KEY (post_id, user_id)
);

CREATE TABLE IF NOT EXISTS followers (
    follower_id INT REFERENCES users(user_id),
    followee_id INT REFERENCES users(user_id),
    PRIMARY KEY (follower_id, followee_id)
);
