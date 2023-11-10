#!/bin/bash

#
### download, verify, install Thunderhub (Lnd manager in web browser)
#

#-----------------------------------------------------------------

#
### Config
#
source CONFIG

#-----------------------------------------------------------------

#
### check if root, otherwise exit
#
if [ "$EUID" -ne 0 ]; then
  echo -e "${R}Please run the installation script as root!${NC}"
  exit
fi

#-----------------------------------------------------------------

# clear screen
clear

#-----------------------------------------------------------------

#
### Check if user really wants to install...or exit
#
echo
echo -e "${Y}This script will download, verify and install Mempool...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Upgrade system to newest software (apt update / apt upgrade)"
echo "- Clone Thunderhub Github repository, version ${THH_VERSION}"
echo "- Get thunderhub user account and password (by user interaction)"
echo "- Create thunderhub environment config file ()${THH_ENV_CONF_FILE})"
echo "- Create thunderhub config dir and write yaml config (${THH_YAML_CONF_FILE})"
echo "- Build the thunderhub application"
echo "- Change permissions for thunderhub base and config dir for user ${USER}"
echo "- Create systemd ${THH_SERVICE} service file"
echo "- Create nginx configs, check nginx and restart nginx web server"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

# clear screen
clear

#-----------------------------------------------------------------

#
### update / upgrade system
#
echo
echo -e "${Y}Updating the system via apt...${NC}"
apt-get -q update && apt upgrade -y
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### cd into homedir and download thunderhub git repository /home/satoshi
#
echo
echo -e "${Y}Cd into ${HOME_DIR} and clone thunderhub git repository...${NC}"
cd "${HOME_DIR}"
# delete dir if exist
rm -rf "${THH_DIR}"
git clone https://github.com/apotdevin/thunderhub.git
cd "${THH_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### get the latest release from github and checkout git there
#
echo
echo -e "${Y}Get latest release and git checkout at this release...${NC}"
latestrelease="v${THH_VERSION}"
git -c advice.detachedHead=false checkout "${latestrelease}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### request admin password from user again for the config
#
echo
echo -e "${LR}Please enter an ${NC}Account user${LR} for thunderhub and press the ${NC}<enter>${LR} key (for yaml config):${NC}"
read -r THH_USER
echo -e "${LR}Please enter the ${NC}Master password${LR} for thunderhub and press the ${NC}<enter>${LR} key (for yaml config):${NC}"
read -r THH_PASS

#-----------------------------------------------------------------

#
### request user to note down user and master pass
#
echo
echo -e "${LR}Note down ${NC}Account user${LR} and ${NC}Master password${LR} just entered as pw will be hashed after 1st start!! Press ${NC}<enter>${LR} key to go on:${NC}"
read -r

#-----------------------------------------------------------------

#
### create thunderhub environment config file env.local
#
echo
echo -e "${Y}Write Thunderhub ${THH_ENV_CONF_FILE} file...${NC}"
cat > "${THH_ENV_CONF_FILE}"<< EOF
#
# Info: https://docs.thunderhub.io/setup
# Check .env file for more config options
#
TOR_PROXY_SERVER=socks://127.0.0.1:9050
MEMPOOL_URL='http://127.0.0.1:4080/de/'
ACCOUNT_CONFIG_PATH='${THH_YAML_CONF_FILE}'
DISABLE_LINKS=true
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create thunderhub config dir and write yaml config
#
echo
echo -e "${Y}Create config dir and write ${THH_YAML_CONF_FILE} file...${NC}"
mkdir -p "${THH_CONF_DIR}"
cat > "${THH_YAML_CONF_FILE}"<< EOF
masterPassword: ${THH_PASS}
accounts:
  - name: ${THH_USER}
    serverUrl: 127.0.0.1:10009
    macaroonPath: ${LND_ADMIN_MACAROON_FILE}
    certificatePath: ${LND_CERT_FILE}
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### build the thunderhub application
#
echo
echo -e "${Y}Build the Thunderhub application...${NC}"
echo -e "${LB}This can take several minutes!${NC}"
# opt out from Next.js Telemetry data collection
npx next telemetry disable
# update npm
npm install -g npm@10.2.3
cd "${THH_DIR}"
npm install
npm run build
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### clean up npm caches from build
#
echo
echo -e "${Y}Clean npm caches from build...${NC}"
# clean the npm cache and delete npm cache dir
npm cache clean --force
# npm prune to free some space
npm prune --production
rm -rf "$(npm get cache)"
# delete Cypress frontend test tool from .cache dir
rm -rf /root/.cache/Cypress
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permissions of the thunderhub/.thunderhub dirs to user satoshi
#
echo
echo -e "${Y}Change permissions of ${THH_DIR} to user ${USER}...${NC}"
chown -R "${USER}":"${USER}" "${THH_DIR}"
chown -R "${USER}":"${USER}" "${THH_CONF_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create systemd service for for Thunderhub
#
echo
echo -e "${Y}Create systemd service file for Thunderhub...${NC}"
cat > "${THH_SERVICE_FILE}"<< EOF
[Unit]
Description=Thunderhub
Wants=lnd.service
After=network.target lnd.service

[Service]
WorkingDirectory=${THH_DIR}
ExecStart=/usr/bin/npm start
User=${USER}
Group=${USER}
Restart=always
TimeoutSec=120
RestartSec=30
StandardOutput=null
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### nginx Thunderhub app config snippet
#
echo
echo -e "${Y}Create nginx Thunderhub Nginx streams-enabled dir...${NC}"
mkdir -p /etc/nginx/streams-enabled
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### nginx thunderhub ssl config
#
echo
echo -e "${Y}Write nginx Thunderhub ssl config file (${THH_NGINX_SSL_CONF})...${NC}"
cat > "${THH_NGINX_SSL_CONF}"<< EOF
upstream thunderhub {
  server 127.0.0.1:3000;
}
server {
  listen 4001 ssl;
  proxy_pass thunderhub;
}

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### check nginx config
#
echo
echo -e "${Y}Checking nginx configs...${NC}"
nginx -t
if [ "$?" -eq 0 ]; then
  echo -e "${G}Nginx configs: OK${NC}"
else
  echo -e "${R}Nginx configs: Not OK${NC}"
  exit
fi
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### restart nginx webserver
#
echo
echo -e "${Y}Restart Nginx web server...${NC}"
systemctl restart nginx
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Installation all done!${NC}"
echo
echo -e "${LB}Systemd Service (as root or with sudo as user):${NC}"
echo -e " systemctl enable ${THH_SERVICE} - enable Thunderhub service after boot\n" \
        "systemctl start ${THH_SERVICE}  - start Thunderhub service\n" \
        "systemctl stop ${THH_SERVICE}   - stop Thunderhub service\n" \
        "systemctl status ${THH_SERVICE} - show Thunderhub service status" | column -t -s "+"
echo
echo -e "${LB}View Log:${NC}"
echo " journalctl -fu ${THH_SERVICE}"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${THH_DIR} + - Thunderhub base directory\n" \
        "${THH_ENV_CONF_FILE} + - Thunderhub env config file\n" \
        "${THH_CONF_DIR} + - Thunderhub config dir\n" \
        "${THH_YAML_CONF_FILE} + - Thunderhub yaml config file\n" \
        "+\n" \
        "${THH_SERVICE_FILE} + - Thunderhub systemd service file\n" \
        "+\n" \
        "${THH_NGINX_SSL_CONF} + - Thunderhub Nginx ssl config" | column -t -s "+"
echo
echo
echo -e "${LB}Open Thunderhub page in your browser via the following URL: ${NC}"
echo " https://${LOCAL_IP}:4001"
echo -e "${LB}Login with your Account user and Master password.${NC}"
echo

