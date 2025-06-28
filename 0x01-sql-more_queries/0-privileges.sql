-- 0-privileges.sql
-- Lists privileges granted to a MySQL user

-- Show grants for a specific user
SHOW GRANTS FOR 'user_0d_1'@'localhost';

-- Show all users and their global privileges
SELECT User, Host, Grant_priv, Super_priv
FROM mysql.user;
