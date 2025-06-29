-- MySQL Replication Setup Overview

-- On Master Server:
-- Ensure server-id is set in my.cnf
-- Enable binary logging
-- GRANT REPLICATION SLAVE on *.* to 'replica_user'@'%' IDENTIFIED BY 'password';
-- FLUSH PRIVILEGES;

-- Show master status
SHOW MASTER STATUS;

-- On Slave Server:
-- Set server-id in my.cnf (must be unique)
-- Start replication process
CHANGE MASTER TO
    MASTER_HOST='master_host_ip',
    MASTER_USER='replica_user',
    MASTER_PASSWORD='password',
    MASTER_LOG_FILE='mysql-bin.000001',
    MASTER_LOG_POS=  4;

START SLAVE;

-- Check slave status
SHOW SLAVE STATUS\G
