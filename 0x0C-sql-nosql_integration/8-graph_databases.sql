-- =====================================================
-- File: 8-graph_databases.sql
-- Description: Graph database concepts using SQL
-- Author: Alpha0-1
-- Purpose: Demonstrate graph database patterns in SQL
-- =====================================================

-- Graph databases store data as nodes and relationships
-- While SQL isn't natively graph-oriented, we can model graph structures

-- Create tables to represent graph structure
-- Nodes table - represents entities in our graph
CREATE TABLE IF NOT EXISTS nodes (
    id SERIAL PRIMARY KEY,
    label VARCHAR(50) NOT NULL,
    properties JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Edges table - represents relationships between nodes
CREATE TABLE IF NOT EXISTS edges (
    id SERIAL PRIMARY KEY,
    from_node_id INTEGER REFERENCES nodes(id),
    to_node_id INTEGER REFERENCES nodes(id),
    relationship_type VARCHAR(50) NOT NULL,
    properties JSONB DEFAULT '{}',
    weight DECIMAL(10,2) DEFAULT 1.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data: Social network graph
INSERT INTO nodes (label, properties) VALUES
('Person', '{"name": "Alice", "age": 30, "city": "New York"}'),
('Person', '{"name": "Bob", "age": 25, "city": "San Francisco"}'),
('Person', '{"name": "Charlie", "age": 35, "city": "Chicago"}'),
('Person', '{"name": "Diana", "age": 28, "city": "Boston"}'),
('Company', '{"name": "TechCorp", "industry": "Technology"}'),
('Company', '{"name": "DataInc", "industry": "Analytics"}');

-- Create relationships
INSERT INTO edges (from_node_id, to_node_id, relationship_type, properties) VALUES
(1, 2, 'FRIENDS', '{"since": "2020-01-15"}'),
(2, 3, 'FRIENDS', '{"since": "2019-06-20"}'),
(1, 3, 'FRIENDS', '{"since": "2021-03-10"}'),
(1, 5, 'WORKS_FOR', '{"position": "Engineer", "start_date": "2022-01-01"}'),
(2, 6, 'WORKS_FOR', '{"position": "Analyst", "start_date": "2021-08-15"}'),
(3, 5, 'WORKS_FOR', '{"position": "Manager", "start_date": "2020-12-01"}');

-- Graph traversal queries

-- 1. Find all friends of Alice
SELECT 
    n2.properties->>'name' as friend_name
FROM nodes n1
JOIN edges e ON n1.id = e.from_node_id
JOIN nodes n2 ON e.to_node_id = n2.id
WHERE n1.properties->>'name' = 'Alice'
AND e.relationship_type = 'FRIENDS';

-- 2. Find mutual friends between Alice and Charlie
WITH alice_friends AS (
    SELECT e.to_node_id as friend_id
    FROM nodes n
    JOIN edges e ON n.id = e.from_node_id
    WHERE n.properties->>'name' = 'Alice'
    AND e.relationship_type = 'FRIENDS'
),
charlie_friends AS (
    SELECT e.to_node_id as friend_id
    FROM nodes n
    JOIN edges e ON n.id = e.from_node_id
    WHERE n.properties->>'name' = 'Charlie'
    AND e.relationship_type = 'FRIENDS'
)
SELECT n.properties->>'name' as mutual_friend
FROM alice_friends af
JOIN charlie_friends cf ON af.friend_id = cf.friend_id
JOIN nodes n ON af.friend_id = n.id;

-- 3. Find people who work at the same company as Alice
SELECT DISTINCT
    n2.properties->>'name' as colleague_name,
    company.properties->>'name' as company_name
FROM nodes alice
JOIN edges e1 ON alice.id = e1.from_node_id
JOIN nodes company ON e1.to_node_id = company.id
JOIN edges e2 ON company.id = e2.to_node_id
JOIN nodes n2 ON e2.from_node_id = n2.id
WHERE alice.properties->>'name' = 'Alice'
AND e1.relationship_type = 'WORKS_FOR'
AND e2.relationship_type = 'WORKS_FOR'
AND n2.id != alice.id;

-- 4. Calculate degree centrality (number of connections)
SELECT 
    n.properties->>'name' as person_name,
    COUNT(e.id) as degree_centrality
FROM nodes n
LEFT JOIN edges e ON n.id = e.from_node_id OR n.id = e.to_node_id
WHERE n.label = 'Person'
GROUP BY n.id, n.properties->>'name'
ORDER BY degree_centrality DESC;

-- 5. Find shortest path between two nodes (using recursive CTE)
WITH RECURSIVE path_finder AS (
    -- Base case: direct connections
    SELECT 
        from_node_id,
        to_node_id,
        1 as path_length,
        ARRAY[from_node_id, to_node_id] as path
    FROM edges
    WHERE from_node_id = 1  -- Starting from Alice (id=1)
    
    UNION ALL
    
    -- Recursive case: extend paths
[O    SELECT 
        pf.from_node_id,
        e.to_node_id,
        pf.path_length + 1,
        pf.path || e.to_node_id
    FROM path_finder pf
    JOIN edges e ON pf.to_node_id = e.from_node_id
    WHERE pf.path_length < 5  -- Limit depth to prevent infinite recursion
    AND NOT (e.to_node_id = ANY(pf.path))  -- Avoid cycles
)
SELECT 
    path_length,
    path,
    n1.properties->>'name' as start_person,
    n2.properties->>'name' as end_person
FROM path_finder pf
JOIN nodes n1 ON pf.from_node_id = n1.id
JOIN nodes n2 ON pf.to_node_id = n2.id
WHERE pf.to_node_id = 3  -- Ending at Charlie (id=3)
ORDER BY path_length
LIMIT 1;

-- 6. Graph analytics: Find triangles in the graph
SELECT DISTINCT
    n1.properties->>'name' as person1,
    n2.properties->>'name' as person2,
    n3.properties->>'name' as person3
FROM edges e1
JOIN edges e2 ON e1.to_node_id = e2.from_node_id
JOIN edges e3 ON e2.to_node_id = e3.from_node_id AND e3.to_node_id = e1.from_node_id
JOIN nodes n1 ON e1.from_node_id = n1.id
JOIN nodes n2 ON e1.to_node_id = n2.id
JOIN nodes n3 ON e2.to_node_id = n3.id
WHERE e1.relationship_type = 'FRIENDS'
AND e2.relationship_type = 'FRIENDS'
AND e3.relationship_type = 'FRIENDS';

-- Create indexes for better graph query performance
CREATE INDEX IF NOT EXISTS idx_edges_from_node ON edges(from_node_id);
CREATE INDEX IF NOT EXISTS idx_edges_to_node ON edges(to_node_id);
CREATE INDEX IF NOT EXISTS idx_edges_relationship ON edges(relationship_type);
CREATE INDEX IF NOT EXISTS idx_nodes_label ON nodes(label);
CREATE INDEX IF NOT EXISTS idx_nodes_properties ON nodes USING GIN(properties);

-- Example of graph database pattern: Recommendation system
-- Find friend-of-friend recommendations for Alice
WITH alice_friends AS (
    SELECT e.to_node_id as friend_id
    FROM nodes n
    JOIN edges e ON n.id = e.from_node_id
    WHERE n.properties->>'name' = 'Alice'
    AND e.relationship_type = 'FRIENDS'
)
SELECT 
    n.properties->>'name' as recommended_friend,
    COUNT(*) as mutual_friends_count
FROM alice_friends af
JOIN edges e ON af.friend_id = e.from_node_id
JOIN nodes n ON e.to_node_id = n.id
WHERE e.relationship_type = 'FRIENDS'
AND e.to_node_id NOT IN (
    SELECT friend_id FROM alice_friends
    UNION
    SELECT 1  -- Alice's own ID
)
GROUP BY n.id, n.properties->>'name'
ORDER BY mutual_friends_count DESC;
