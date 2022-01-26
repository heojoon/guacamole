# Guacamole



* docker-compose.yml

~~~yml
version: '3.1'

services:
  guacd:
    image: guacamole/guacd
    ports:
      - 4822:4822

  mysql:
    image: mysql:8.0.28
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - /app/mysql:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: rootPassword

  guacamole:
    image: guacamole/guacamole
    ports:
      - 8080:8080
    environment:
      MYSQL_DATABASE: guacamole_db
      MYSQL_USER: guacamole_user
      MYSQL_PASSWORD: guacamolePassword
~~~



* mysql setting
  * initdb 스크립트 생성

~~~bash
 docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql > initdb.sql
~~~



* 위의 initdb 스크립스 생성 전에 DB와 User를 만들어 줘야한다.

~~~mysql
CREATE DATABASE guacamole_db;
CREATE USER 'guacamole_user'@'localhost' IDENTIFIED BY 'guacamolePassword';
CREATE USER 'guacamole_user'@'172.29.%' IDENTIFIED BY 'guacamolePassword';

GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'172.29.%';
GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'localhost';
FLUSH PRIVILEGES;
~~~

* 패스워드 변경

~~~mysql
ALTER USER 'guacamole_user'@'localhost' IDENTIFIED BY 'guacamolePassword';
~~~


* database auth (mysql)
  * create database and user
~~~
CREATE DATABASE guacamole_db;
CREATE USER 'guacamole_user'@'%' IDENTIFIED BY 'guacamolePassword';
CREATE USER 'guacamole_user'@'localhost' IDENTIFIED BY 'guacamolePassword';
GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'%';
GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'localhost';
FLUSH PRIVILEGES;
~~~
  * use init database
~~~
docker exec mysql mysql -uguacamole_user -p'guacamolePassword' guacamole_db < initdb.sql
~~~
> 위의 내용이 잘 안되면.. docker 내부로 들어가서 작업을 해준다.

* web ui login
> guacadmin / guacadmin


