#!/bin/bash

#
### download, verify, install BTC RPC Explorer (Self-Hosted Bitcoin explorer)
#

# fail if a command fails and exit
set -e

#-----------------------------------------------------------------

#
### check if CONFIG file is there and not empty, otherwise exit
#
if [[ ! -f CONFIG || ! -s CONFIG ]] ; then
    echo '"CONFIG" file is not there or empty, exiting.'
    exit
fi

#-----------------------------------------------------------------

#
### Config
#
. CONFIG

#-----------------------------------------------------------------

#
### check if root, otherwise exit
#
if [ "$EUID" -ne 0 ]; then
  echo -e "${R}Please run the installation script as root!${NC}"
  exit
else
  # set PATH env var for sbin and bin dirs (su root fails the installation)
  export PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
fi

#-----------------------------------------------------------------

# clear screen
clear

#-----------------------------------------------------------------

#
### Check if user really wants to install...or exit
#
echo
echo -e "${Y}This script will download, verify and install BTC-RPC-Explorer...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Upgrade system to newest software (apt-get update / apt-get upgrade)"
echo "- Clone btc-rpc-explorer Github repository, version ${EXPLORER_VERSION}"
echo "- Get rpc-explorer password (by user interaction)"
echo "- Create Explorer config file (${EXPLORER_CONF_FILE})"
echo "- Build the btc-rpc-explorer application"
echo "- Change permissions for Explorer base dir for user ${USER}"
echo "- Create systemd ${EXPLORER_SERVICE} service file"
echo "- Create nginx configs, check nginx and reload nginx web server"
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
echo -e "${Y}Updating the system via apt-get...${NC}"
apt-get -q update && apt-get upgrade -y
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### cd into homedir and download thunderhub git repository /home/satoshi
#
echo
echo -e "${Y}Cd into ${HOME_DIR} and clone the Explorer git repository...${NC}"
cd "${HOME_DIR}"
# delete dir if exist
rm -rf "${EXPLORER_DIR}"
git clone https://github.com/janoside/btc-rpc-explorer
cd "${EXPLORER_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### get the latest release from github and checkout git there
#
echo
echo -e "${Y}Get latest release and git checkout at this release...${NC}"
latestrelease="v${EXPLORER_VERSION}"
git -c advice.detachedHead=false checkout "${latestrelease}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### request rpcuser and rpcpass from user again for the config
#
echo
echo -e "${LR}Please enter your ${NC}rpcuser${LR} used in bitcoind script and press the ${NC}<enter>${LR} key (for config):${NC}"
read -r RPCUSER
echo -e "${LR}Please enter your ${NC}rpcpass${LR} used in bitcoind script and press the ${NC}<enter>${LR} key (for config):${NC}"
read -r RPCPASS

#-----------------------------------------------------------------

#
### request user to enter a password for the web access (for config)
#
echo
echo -e "${LR}Please enter a ${NC}password${LR} to login into the Explorer web page and press the ${NC}<enter>${LR} key (for config):${NC}"
read -r EXPLORER_PASS

#-----------------------------------------------------------------

#
### create explorer config file env.local
#
echo
echo -e "${Y}Write Explorer ${EXPLORER_CONF_FILE} config file...${NC}"
cat > "${EXPLORER_CONF_FILE}"<< EOF
#
# BTC-RPC-Explorer config
# Check .env-sample file for more config options
#
BTCEXP_BASEURL=/

BTCEXP_HOST=127.0.0.1
BTCEXP_PORT=3002

BTCEXP_BITCOIND_HOST=127.0.0.1
BTCEXP_BITCOIND_PORT=8332
BTCEXP_BITCOIND_USER=${RPCUSER}
BTCEXP_BITCOIND_PASS=${RPCPASS}
BTCEXP_BITCOIND_COOKIE=~/.bitcoin/.cookie
BTCEXP_BITCOIND_RPC_TIMEOUT=5000

BTCEXP_ADDRESS_API=electrum
BTCEXP_ELECTRUM_SERVERS=tls://127.0.0.1:50002

BTCEXP_DEMO=false

BTCEXP_BASIC_AUTH_PASSWORD=${EXPLORER_PASS}

BTCEXP_RPC_ALLOWALL=true
BTCEXP_RPC_BLACKLIST=signrawtransaction,sendtoaddress,stop,...

BTCEXP_FILESYSTEM_CACHE_DIR=./cache

BTCEXP_LOCAL_CURRENCY=eur
BTCEXP_UI_TIMEZONE=local
BTCEXP_UI_THEME=dark
BTCEXP_UI_HIDE_INFO_NOTES=false
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### build the explorer application
#
echo
echo -e "${Y}Build the Explorer application...${NC}"
echo -e "${LB}This can take several minutes!${NC}"
# install/build
cd "${EXPLORER_DIR}"
# update npm (based on warnings)
npm install -g npm@${NPM_UPD_VER}
npm install
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### clean up npm caches from build
#
echo
echo -e "${Y}Clean npm caches from build...${NC}"
# clean the npm cache and delete npm cache dir
npm cache clean --force
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permissions of the explorer dir to user satoshi
#
echo
echo -e "${Y}Change permissions of ${EXPLORER_DIR} to user ${USER}...${NC}"
chown -R "${USER}":"${USER}" "${EXPLORER_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create systemd service for for Thunderhub
#
echo
echo -e "${Y}Create systemd service file for Explorer...${NC}"
cat > "${EXPLORER_SERVICE_FILE}"<< EOF
[Unit]
Description=BTC-RPC-Explorer

[Service]
User=satoshi
Group=satoshi
Restart=always
WorkingDirectory=/home/satoshi/btc-rpc-explorer
ExecStart=/usr/bin/npm start /home/satoshi/btc-rpc-explorer

[Install]
WantedBy=multi-user.target
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### nginx explorer ssl config
#
echo
echo -e "${Y}Write nginx Explorer ssl config file (${EXPLORER_NGINX_SSL_CONF})...${NC}"
cat > "${EXPLORER_NGINX_SSL_CONF}"<< EOF
upstream explorer {
        server 127.0.0.1:3002 max_fails=1 weight=4;
}

server {
        listen 4032 ssl;
        listen [::]:4032 ssl;
        proxy_pass explorer;
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
### reload nginx webserver
#
echo
echo -e "${Y}Restart Nginx web server...${NC}"
systemctl reload nginx
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Installation all done!${NC}"
echo
echo -e "${LB}Systemd Service (as root or with sudo as user):${NC}"
echo -e " systemctl enable ${EXPLORER_SERVICE} - enable Explorer service after boot\n" \
        "systemctl start ${EXPLORER_SERVICE}  - start Explorer service\n" \
        "systemctl stop ${EXPLORER_SERVICE}   - stop Explorer service\n" \
        "systemctl status ${EXPLORER_SERVICE} - show Explorer service status" | column -t -s "+"
echo
echo -e "${LB}View Log:${NC}"
echo " journalctl -fu ${EXPLORER_SERVICE}"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${EXPLORER_DIR} + - Explorer base directory\n" \
        "${EXPLORER_CONF_FILE} + - Explorer .env config file\n" \
        "+\n" \
        "${EXPLORER_SERVICE_FILE} + - Explorer systemd service file\n" \
        "+\n" \
        "${EXPLORER_NGINX_SSL_CONF} + - Explorer Nginx ssl config" | column -t -s "+"
echo
echo
echo -e "${LB}Open Explorer page in your browser via the following URL: ${NC}"
echo " https://${LOCAL_IP}:4032"
echo -e "${LB}Login with your password (leaving username empty).${NC}"
echo

