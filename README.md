# Apache Guacamole

## 소개

* Apache Guacamole은 Apache Software Foundation에서 유지 관리하는 무료 오픈 소스 크로스 플랫폼 원격 데스크톱 게이트웨이입니다. 이를 통해 사용자는 웹 브라우저를 통해 원격 컴퓨터 또는 가상 머신을 제어할 수 있습니다. 

* Apache Guacamole 는 클라이언트 없이 웹브라우저로 원격 접속을 가능하게 해주는 게이트웨이 이며 지원하는 프로토콜은 VNC,RDP ,SSH 등이 있습니다. 



## Installation

* 빠른 설치를 위해서 docker-compose를 사용하였습니다. apache guacamole 공식 홈페이지에는 single docker 를 이용한 설치 가이드만 있습니다.
* 구성을 위한 기본 컴포넌트는 guacd , mysql ,guacamole 이 필요합니다.



### Docker-compose 

* Instatll docker-compose
* docker-compose.yml

~~~yml
version: '3.1'

services:
  guacd:
    container_name: guacd
    image: guacamole/guacd
    ports:
      - 4822:4822
    environment: 
      GUACD_HOSTNAME: guacd 
      GUACD_PORT: 4822
      GUACD_LOG_LEVEL: debug

  mysql:
    container_name: mysql
    image: mysql:5.7.37
    command: --default-authentication-plugin=mysql_native_password
    ports:
      - 3306:3306
    volumes:
      - /app/mysql/data:/var/lib/mysql
      - /app/mysql/etc/mysql:/etc/mysql
    environment: 
      MYSQL_ROOT_PASSWORD: rootPassword

  guacamole:
    depends_on:
      - guacd
      - mysql
    links:
      - guacd:guacd
      - mysql:mysql
    container_name: guacamole
    image: guacamole/guacamole
    ports: 
      - 8080:8080
    environment:
      MYSQL_DATABASE: guacamole_db
      MYSQL_USER: guacamole_user
      MYSQL_PASSWORD: guacamolePassword
      GUACD_HOSTNAME: guacd 
      GUACD_PORT: 4822
      MYSQL_HOSTNAME: mysql
      MYSQL_PORT: 3306
      MYSQL_SSL_MODE: disabled
~~~



### Mysql setting



* initdb 스크립트 생성

~~~bash
 docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql > initdb.sql
~~~

* 위의 initdb 스크립스 생성 전에 DB와 User를 만들어 줘야한다.
  * 172.29.% , localhost 2개 다 필요하다 - 내부 접속 용도 , 외부 접속 용도

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
