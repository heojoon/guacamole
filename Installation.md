# gacamole install use docker-compose

## database auth (mysql)
* 1. create database and user
~~~
CREATE DATABASE guacamole_db;
CREATE USER 'guacamole_user'@'%' IDENTIFIED BY 'guacamolePassword';
CREATE USER 'guacamole_user'@'localhost' IDENTIFIED BY 'guacamolePassword';
GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'%';
GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'localhost';
FLUSH PRIVILEGES;
~~~

* 2. use init database 
~~~
docker exec mysql mysql -uguacamole_user -p'guacamolePassword' guacamole_db < initdb.sql
~~~
  * 위의 내용이 잘 안되면.. docker 내부로 들어가서 작업을 해준다.

* 3. web ui login
~~~
guacadmin / guacadmin
~~~

