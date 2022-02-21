# Apache Guacamole

# 1. 소개

* Apache Guacamole은 Apache Software Foundation에서 유지 관리하는 무료 오픈 소스 크로스 플랫폼 원격 데스크톱 게이트웨이입니다. 이를 통해 사용자는 웹 브라우저를 통해 원격 컴퓨터 또는 가상 머신을 제어할 수 있습니다. 

* Apache Guacamole 는 클라이언트 없이 웹브라우저로 원격 접속을 가능하게 해주는 게이트웨이 이며 지원하는 프로토콜은 VNC,RDP ,SSH 등이 있습니다. 



# 2. Installation

* 빠른 설치를 위해서 docker-compose를 사용하였습니다. apache guacamole 공식 홈페이지에는 single docker 를 이용한 설치 가이드만 있습니다.
* 구성을 위한 기본 컴포넌트는 guacd , mysql ,guacamole 이 필요합니다.



## 2.1. Docker-compose 

* Instatll docker-compose

~~~bash
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose --version
~~~

>반드시 docker는 설치되어 있어야 합니다.



* docker-compose.yml 를 생성합니다.

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

* docker-compose 를 실행합니다.

~~~bash
ls docker-compose.yml
docker-compose.yml

docker-compose up -d
~~~

* 비록 guacamole , mysql의 실행이 실패할 것이지만 이 수순이 정상입니다.
  * 아직 mysql 데이터 베이스가 미구성 상태입니다.



## 2.2. Mysql setting

* 1.  DB와 User를 수동으로 생성합니다.

  * 172.% , localhost 2개 다 필요합니다. - 내부 접속 용도 , 외부 접속 용도

~~~mysql
CREATE DATABASE guacamole_db;
CREATE USER 'guacamole_user'@'localhost' IDENTIFIED BY 'guacamolePassword';
CREATE USER 'guacamole_user'@'172.%' IDENTIFIED BY 'guacamolePassword';

GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'172.%';
GRANT ALL ON guacamole_db.* TO 'guacamole_user'@'localhost';
FLUSH PRIVILEGES;
~~~

>  [참고] 패스워드 변경이 필요한 경우

~~~mysql
ALTER USER 'guacamole_user'@'localhost' IDENTIFIED BY 'guacamolePassword';
~~~

* 2. initdb 스크립트 생성 (gucamole 초기 메타설정 스크립트)

  * guacamole container image 파일 내에  생성 스크립트를 이용합니다.

~~~bash
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql > initdb.sql
~~~

* 3. initdb 스크립트를 수행합니다.

~~~bash
docker exec -i mysql mysql -u'guacamole_user' -p'guacamolePassword' guacamole_db < initdb.sql
~~~

* 4. initdb 스크립트가 정상적으로 수행되었는지 확인합니다.

~~~bash
docker exec -it mysql mysql -u'guacamole_user' -p'guacamolePassword' 

sql> use guacamole_db;
sql> show tables;
~~~

> 테이블이 정상적으로 보이면 성공, 테이블이 안보이면 실패, 실패시 아래 5.번 가이드대로 합니다.

* 5.  mysql container 내부로 들어가서 initdb 스크립트를 수행합니다. (4번 실패시에만 수행)

~~~bash
# 먼저 initdb.sql 파일을 mysql container 내부에서 접근할 수 있도록 volumn mount 한 디렉토리로 복사합니다.
cp initdb.sql /app/mysql/data

# docker 내부로 들어갑니다.
docker exec -it mysql bash
cd /var/lib/mysql
mysql -u'guacamole_user' -p'guacamolePassword' guacamole_db < initdb.sql
~~~

* 6. 작업이 끝난 후 테이블을 확인합니다.  (4번 과정 반복)



## 2.3. WEB 화면 접속


* 웹 브라우저를  실행하고 아래 URL로 접속합니다.

  *  http://{TEST.guacamole.com}:8080/guacamole/
  * ID :  guacadmin / PW : guacadmin
* 로그인 화면이 뜨고 위의 ID/PW로 로그인 되면 성공입니다.


## 2.x. 트러블슈팅

* 자주 접했던 500에러가 발생했을 경우 로그 확인
~~~
docker logs -f guacamole
~~~

* 원인
~~~
### Error querying database.  Cause: java.sql.SQLException: Access denied for user 'guacamole_user'@'guacamole.ubuntu_default'(using password: YES)
~~~

* 해결
~~~
docker exec -i mysql mysql -u'guacamole_user' -p'guacamolePassword' guacamole_db -e \ 
"CREATE USER 'guacamole_user'@'guacamole.ubuntu_default' IDENTIFIED BY 'guacamolePassword'"

docker exec -i mysql mysql -u'guacamole_user' -p'guacamolePassword' guacamole_db -e \ 
"GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'guacamole.ubuntu_default'"

docker exec -i mysql mysql -u'guacamole_user' -p'guacamolePassword' guacamole_db -e \ 
"FLUSH PRIVILEGES"
~~~




# 3. amazon linux2 VNC 

## 3.1. 소개

* Linux 서버에 VNC 접속 (GUI)을 위한 단계입니다.  
* amazon linux2는 mate desktop을 사용합니다. 
* 크롬브라우저를 설치합니다.
* tiger vnc를 설치합니다.

>  [참고] [amazon linux gui install guide](https://aws.amazon.com/ko/premiumsupport/knowledge-center/ec2-linux-2-install-gui/)

> [참고] [mate desktop official home page](https://mate-desktop.org/)



## 3.2. Installation 

~~~bash
sudo yum -y update
# 서버 리부팅
reboot

# MATE 패키지를 설치합니다.
sudo amazon-linux-extras install mate-desktop1.x

# 모든 사용자에 대해 MATE 정의
sudo bash -c 'echo PREFERRED=/usr/bin/mate-session > /etc/sysconfig/desktop'

# vnc 서버 설치
sudo yum -y install tigervnc-server

# vnc 패스워드 구성 (나는 vnc1234로 설정)
vncpasswd

# vnc display 번호 설정, 구동
vncserver :1

# vncserver 서비스 등록 
# - 위 과정의 vncserver :1 이 있기 때문에 아래 내용의 서비스가 구동되지 않음
sudo cp /lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@.service

sudo systemctl daemon-reload
sudo systemctl enable vncserver@:1

sudo systemctl restart vncserver@:1
sudo systemctl status vncserver@:1
~~~



* systemd 스크립트 수정

  * /usr/lib/systemd/system

  ~~~bash
  # VNC를 통해 로그인할 user id 로 변경 (나는 ssm-user로 변경)
  ExecStart=/usr/bin/vncserver_wrapper <USER-NAME> %i
  ->
  ExecStart=/usr/bin/vncserver_wrapper ssm-user %i
  ~~~

  

## 3.3. Install web browser

~~~bash
sudo amazon-linux-extras install -y epel
sudo yum install -y chromium
~~~



## 3.4. guacamole connection setting

https://guacamole.apache.org/doc/gug/configuring-guacamole.html



## 3.5. guacamole security setting

* 기본 관리자 계정인 guacadmin 으로 로그인 해서 신규 계정 생성
  * superadmin / superadmin
  * superadmin 계정에 권한을 모두 할당함 
* 로그아웃 후 superadmin 으로 로그인
* guacadmin  사용자 편집으로 들어가서 > 로그인 비활성화 **체크박스 v**
* 로그아웃 후 guacadmin 으로 로그인이 안되는지 확인



# 4. windows EC2 

* IP/Port

~~~bash
public ip : 1.2.3.4
port : 3389
private ip : 172.1.1.2
~~~

# 5. SSHd Server for win

*  개요

  Guacamole File Transfer 구현을 위해서 sftp/sshd server 구성

* 참고

  * https://github.com/powershell/win32-openssh
  * 설치 매뉴얼
    * https://github.com/PowerShell/Win32-OpenSSH/wiki/Install-Win32-OpenSSH
  * 다운로드
    * https://github.com/PowerShell/Win32-OpenSSH/releases/tag/V8.6.0.0p1-Beta



* 서비스 포트 변경
  * sshd_config 설정 파일 복사

~~~powershell
copy C:\Program Files\OpenSSH\sshd_config_default C:\Program Files\OpenSSH\sshd_config
notepad C:\Program Files\OpenSSH\sshd_config
~~~

* sshd_config 설정 파일 수정

~~~bash
#Port 22 <- Port를 ????22로 변경
Port ????22
~~~

* 시작 -> 실행 -> registry editor

* HKEY_LOCAL_MACHINE\SYSTEM\CurrentContorlSet\Services\sshd

  * ImagePath 수정 (REG_EXPAND_SZ)

  ~~~
  C:\Program Files\OpenSSH\sshd.exe -f sshd_config
  ~~~

*  services.msc 에서 OpenSSH SSH Server 에서 Path to excutable 이 레지스트리 수정 내용이 적용 되었는지 확인
* 재시작
* 윈도우 파워쉘 실행

~~~powershell
# 20022 포트로 리스닝 중인 것 확인
netstat -na -p tcp   
 TCP    0.0.0.0:???22          0.0.0.0:0              LISTENING
~~~
  

* ID : Administrator / PW : **********

* Port : ?????

