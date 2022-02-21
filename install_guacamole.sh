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
        installDockerCompose
        downloadYaml
        [ -e "docker-compose.yml" ] && sudo docker-compose up -d || echo "No file docker-compose.yml"
}


# execution
main
