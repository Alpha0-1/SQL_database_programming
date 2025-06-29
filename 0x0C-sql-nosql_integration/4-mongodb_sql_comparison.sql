-- =====================================================
-- File: 4-mongodb_sql_comparison.sql
-- Description: MongoDB vs SQL comparison with examples
-- Author: Alpha0-1
-- =====================================================

-- Problem Statement: Demonstrate equivalent operations between MongoDB and SQL
-- to help developers understand the conceptual mapping between these paradigms

-- =====================================================
-- 1. DATA MODEL COMPARISON
-- =====================================================

-- SQL: Normalized relational structure
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE posts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    tags JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- MongoDB Equivalent (Document structure - shown as comment):
/*
MongoDB Collection: users
{
  "_id": ObjectId("..."),
  "username": "john_doe",
  "email": "john@example.com",
  "posts": [
    {
      "title": "My First Post",
      "content": "Hello World!",
      "tags": ["intro", "hello"],
      "created_at": ISODate("2024-01-01T10:00:00Z")
    }
  ],
  "created_at": ISODate("2024-01-01T09:00:00Z")
}
*/

-- =====================================================
-- 2. CRUD OPERATIONS COMPARISON
-- =====================================================

-- INSERT OPERATIONS
-- SQL INSERT
INSERT INTO users (username, email) VALUES ('john_doe', 'john@example.com');
INSERT INTO posts (user_id, title, content, tags) 
VALUES (1, 'My First Post', 'Hello World!', JSON_ARRAY('intro', 'hello'));

-- MongoDB equivalent:
-- db.users.insertOne({
--   username: "john_doe",
--   email: "john@example.com",
--   posts: [{
--     title: "My First Post",
--     content: "Hello World!",
--     tags: ["intro", "hello"],
--     created_at: new Date()
--   }],
--   created_at: new Date()
-- });

-- =====================================================
-- 3. QUERY OPERATIONS COMPARISON
-- =====================================================

-- FIND/SELECT operations
-- SQL: Find all users with their posts
SELECT u.username, u.email, p.title, p.content
FROM users u
LEFT JOIN posts p ON u.id = p.user_id
WHERE u.username = 'john_doe';

-- MongoDB equivalent:
-- db.users.find({username: "john_doe"});

-- SQL: Complex filtering with JSON
SELECT u.username, p.title
FROM users u
JOIN posts p ON u.id = p.user_id
WHERE JSON_CONTAINS(p.tags, '"intro"');

-- MongoDB equivalent:
-- db.users.find({"posts.tags": "intro"});

-- =====================================================
-- 4. UPDATE OPERATIONS COMPARISON
-- =====================================================

-- SQL UPDATE
UPDATE users SET email = 'newemail@example.com' WHERE username = 'john_doe';

-- Add new post (SQL requires INSERT)
INSERT INTO posts (user_id, title, content, tags)
SELECT id, 'Second Post', 'More content', JSON_ARRAY('update', 'sql')
FROM users WHERE username = 'john_doe';

-- MongoDB equivalent (atomic update):
-- db.users.updateOne(
--   {username: "john_doe"},
--   {
--     $set: {email: "newemail@example.com"},
--     $push: {
--       posts: {
--         title: "Second Post",
--         content: "More content",
--         tags: ["update", "mongodb"],
--         created_at: new Date()
--       }
--     }
--   }
-- );

-- =====================================================
-- 5. AGGREGATION COMPARISON
-- =====================================================

-- SQL: Aggregation with GROUP BY
SELECT u.username, COUNT(p.id) as post_count, AVG(LENGTH(p.content)) as avg_content_length
FROM users u
LEFT JOIN posts p ON u.id = p.user_id
GROUP BY u.id, u.username;

-- MongoDB equivalent (aggregation pipeline):
-- db.users.aggregate([
--   {$unwind: {path: "$posts", preserveNullAndEmptyArrays: true}},
--   {$group: {
--     _id: "$username",
--     post_count: {$sum: {$cond: [{$ifNull: ["$posts", false]}, 1, 0]}},
--     avg_content_length: {$avg: {$strLenCP: "$posts.content"}}
--   }}
-- ]);

-- =====================================================
-- 6. INDEXING COMPARISON
-- =====================================================

-- SQL Indexes
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_tags ON posts((CAST(tags AS CHAR(255) ARRAY)));

-- MongoDB equivalent:
-- db.users.createIndex({username: 1});
-- db.users.createIndex({"posts.tags": 1});
-- db.users.createIndex({"posts.created_at": -1});

-- =====================================================
-- 7. SCHEMA FLEXIBILITY DEMONSTRATION
-- =====================================================

-- SQL: Adding new field requires schema change
ALTER TABLE users ADD COLUMN profile_picture VARCHAR(255);

-- Insert with new field
INSERT INTO users (username, email, profile_picture) 
VALUES ('jane_doe', 'jane@example.com', 'profile.jpg');

-- MongoDB: No schema change needed
-- db.users.insertOne({
--   username: "jane_doe",
--   email: "jane@example.com",
--   profile_picture: "profile.jpg",
--   bio: "Software developer",  // New field added without schema change
--   social_links: {             // Nested object
--     twitter: "@jane_doe",
--     github: "jane-dev"
--   }
-- });

-- =====================================================
-- 8. TRANSACTION COMPARISON
-- =====================================================

-- SQL Transaction
START TRANSACTION;
INSERT INTO users (username, email) VALUES ('alice', 'alice@example.com');
INSERT INTO posts (user_id, title, content, tags) 
VALUES (LAST_INSERT_ID(), 'Alice Post', 'Content', JSON_ARRAY('test'));
COMMIT;

-- MongoDB Transaction (requires replica set):
-- session = db.getMongo().startSession();
-- session.startTransaction();
-- try {
--   db.users.insertOne({username: "alice", email: "alice@example.com"}, {session});
--   session.commitTransaction();
-- } catch (error) {
--   session.abortTransaction();
--   throw error;
-- } finally {
--   session.endSession();
-- }

-- =====================================================
-- 9. PERFORMANCE CONSIDERATIONS
-- =====================================================

-- SQL: Optimized for joins and complex queries
EXPLAIN SELECT u.username, COUNT(p.id) as post_count
FROM users u
LEFT JOIN posts p ON u.id = p.user_id
GROUP BY u.id, u.username;

-- Show query execution plan
-- MongoDB: Optimized for document retrieval
-- db.users.find({username: "john_doe"}).explain("executionStats");

-- =====================================================
-- 10. USE CASE RECOMMENDATIONS
-- =====================================================

/*
SQL is better for:
- Complex relationships and joins
- ACID transactions across multiple tables
- Structured data with consistent schema
- Complex analytical queries
- Financial and critical business data

MongoDB is better for:
- Flexible, evolving schemas
- Rapid development and prototyping
- Document-based data models
- Horizontal scaling requirements
- Content management systems
- Real-time analytics with simple aggregations

Example use cases:
SQL: E-commerce (orders, payments, inventory)
MongoDB: Social media (posts, comments, user profiles)
*/

-- Cleanup
DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS users;
