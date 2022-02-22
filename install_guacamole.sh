#!/bin/bash

# ---------------------------------------------
# Install Script Guacamole v0.1
#
# sig. hjoon
#
# PreRequirement.
# 1. Installed docker
# 2. sudo authorization
#



# 1. Install docker-compose
function installDockerCompose() {
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
        docker-compose --version
}

# 2.Download docker-compose yaml file
function downloadYaml() {
        wget https://raw.githubusercontent.com/heojoon/guacamole/main/docker-compose.yml
}

# 3. Create Mysql DB and User for Guacamole
function createDBandUser() {
        wget https://raw.githubusercontent.com/heojoon/guacamole/main/createDBandUser.sql
        docker exec -i mysql mysql -uroot -prootPassword < createDBandUser.sql
}

# 4. gucamole init setting
function initGucamoleDB() {
        docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql > initdb.sql
        docker exec -i mysql mysql -u'guacamole_user' -p'guacamolePassword' guacamole_db < initdb.sql
        # Verify created table
        docker exec -i mysql mysql -u'guacamole_user' -p'guacamolePassword' -e "show tables" guacamole_db
}



# Main fucntion
function main() {
        echo "########### Installation Gucamole #################"
        echo "## 1. Install docker-compose"
        installDockerCompose
        
        echo "## 2.Download docker-compose yaml file"
        downloadYaml
        
        echo "## Run docker-compose"
        ## Run docker-compose
        if [ -e "docker-compose.yml" ] ; then
                sudo docker-compose up -d
        else
                echo "[Error] No file docker-compose.yml"
                exit 1
        fi
        echo "## 3. Create Mysql DB and User for Guacamole" ; sleep 3
        createDBandUser
        
        echo "## 4. gucamole init setting" ; sleep 5
        initGucamoleDB
        
        echo "## docker-compose restart"  ; sleep 2
        docker-compose restart
        echo "Done"
}

### execution
main
