-- 7-cities.sql
-- Create cities table with foreign key to states

-- Create cities table with foreign key
CREATE TABLE IF NOT EXISTS cities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    state_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    FOREIGN KEY (state_id)
        REFERENCES states(id)
        ON DELETE CASCADE
);
