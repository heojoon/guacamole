CREATE DATABASE guacamole_db;
CREATE USER 'guacamole_user'@'localhost' IDENTIFIED BY 'guacamolePassword';
CREATE USER 'guacamole_user'@'172.%' IDENTIFIED BY 'guacamolePassword';

GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'172.%';
GRANT ALL ON guacamole_db.* TO 'guacamole_user'@'localhost';
FLUSH PRIVILEGES;
