#!/bin/bash

#
### download, verify, install Ride the Lightning (RTL)
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
echo -e "${Y}This script will download, verify and install the Ride the Lightning (RTL)...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Upgrade system to newest software (apt-get update / apt-get upgrade)"
echo "- Clone RTL Github repository, version ${RTL_VERSION}"
echo "- Get RTL password (by user interaction)"
echo "- Create RTL config file (${RTL_CONF_FILE})"
echo "- Build the RTL application"
echo "- Change permissions of Rtl base dir for user ${USER}"
echo "- Create systemd service file (${RTL_SERVICE_FILE})"
echo "- Create nginx ssl config (${RTL_NGINX_SSL_CONF})"
echo "- Check nginx configs and reload nginx web server"
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
### cd into homedir and download rtl git repository into ${HOME_DIR}
#
echo
echo -e "${Y}Cd into ${HOME_DIR} and clone the RTL git repository...${NC}"
cd "${HOME_DIR}"
# delete dir if exist
rm -rf "${RTL_DIR}"
git clone https://github.com/Ride-The-Lightning/RTL.git
cd "${RTL_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### git checkout at config version
#
echo
echo -e "${Y}Git checkout at config version...${NC}"
latestrelease="v${RTL_VERSION}"
git -c advice.detachedHead=false checkout "${latestrelease}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------
#
### verify the source code
#
echo
echo -e "${Y}Verify the release source code...${NC}"
# download gpg key
wget -O pgp_keys.asc https://keybase.io/suheb/pgp_keys.asc
# import into gpg
gpg --import -q pgp_keys.asc || true
# verify
if ! git verify-tag v"${RTL_VERSION}"; then
  echo -e "${R}The signature(s) for the source code are not good signature. Exiting now.${NC}"
  exit 1
else
  echo -e "${G}The signature(s) for the source code are good signature(s).${NC}"
fi
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### request user to enter a password for the web access (for config)
#
echo
echo -e "${LR}Please enter a ${NC}password${LR} to login into the RTL web page and press the ${NC}<enter>${LR} key (for config):${NC}"
read -r RTL_PASS

#-----------------------------------------------------------------

#
### create rtl config file ${RTL_CONF_FILE}
#
echo
echo -e "${Y}Write RTL ${RTL_CONF_FILE} config file...${NC}"
cat > "${RTL_CONF_FILE}"<< EOF

{
  "multiPass": "${RTL_PASS}",
  "port": "3010",
  "defaultNodeIndex": 1,
  "dbDirectoryPath": "",
  "SSO": {
    "rtlSSO": 0,
    "rtlCookiePath": "",
    "logoutRedirectLink": ""
  },
  "nodes": [
    {
      "index": 1,
      "lnNode": "Node 1",
      "lnImplementation": "LND",
      "Authentication": {
        "macaroonPath": "${LND_DIR}/data/chain/bitcoin/mainnet",
        "configPath": "${LND_CONF_FILE}",
        "swapMacaroonPath": "",
        "boltzMacaroonPath": ""
      },
      "Settings": {
        "userPersona": "MERCHANT",
        "themeMode": "DAY",
        "themeColor": "PURPLE",
        "channelBackupPath": "",
        "logLevel": "ERROR",
        "lnServerUrl": "https://127.0.0.1:8080",
        "swapServerUrl": "https://127.0.0.1:8081",
        "boltzServerUrl": "https://127.0.0.1:9003",
        "fiatConversion": false,
        "unannouncedChannels": false,
        "blockExplorerUrl": "https://127.0.0.1:${MEMPOOL_SSL_PORT}/en/"
      }
    }
  ]
}

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### build the rtl application
#
echo
echo -e "${Y}Build the RTL application...${NC}"
echo -e "${LB}This can take quite some time!${NC}"
cd "${RTL_DIR}"
# update npm (based on warnings)
npm install -g npm@"${NPM_UPD_VER}"
# build
npm install --omit=dev --legacy-peer-deps
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
npm prune --omit=dev --legacy-peer-deps
rm -rf "$(npm get cache)"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permissions of the rtl base dir for user satoshi
#
echo
echo -e "${Y}Change permissions of ${RTL_DIR} for user ${USER}...${NC}"
chown -R "${USER}":"${USER}" "${RTL_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create systemd service file for rtl
#
echo
echo -e "${Y}Create systemd service file for RTL...${NC}"
cat > "${RTL_SERVICE_FILE}"<< EOF
#
# systemd unit for Ride the Lightning
# ${RTL_SERVICE_FILE}
#
[Unit]
Description=RTL daemon
Wants=lnd.service
After=lnd.service

[Service]
WorkingDirectory=${RTL_DIR}
ExecStart=/usr/bin/node ${RTL_DIR}/rtl
User=${USER}

Restart=always
TimeoutSec=120
RestartSec=30

[Install]
WantedBy=multi-user.target

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### nginx rtl reverse proxy ssl config
#
echo
echo -e "${Y}Write nginx RTL reverse proxy ssl config (${RTL_NGINX_SSL_CONF})...${NC}"
cat > "${RTL_NGINX_SSL_CONF}"<< EOF

upstream rtl {
  server 127.0.0.1:3010;
}
server {
  listen ${RTL_SSL_PORT} ssl;
  listen [::]:${RTL_SSL_PORT} ssl;
  proxy_pass rtl;
}

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### check nginx config
#
echo
echo -e "${Y}Checking nginx configs...${NC}"
if nginx -t; then
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
echo -e " systemctl enable ${RTL_SERVICE} - enable RTL service after boot\n" \
        "systemctl start ${RTL_SERVICE}  - start RTL service\n" \
        "systemctl stop ${RTL_SERVICE}   - stop RTL service\n" \
        "systemctl status ${RTL_SERVICE} - show RTL service status" | column -t -s "+"
echo
echo -e "${LB}View Log:${NC}"
echo " journalctl -fu ${RTL_SERVICE}"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${RTL_DIR} + - RTL base directory\n" \
        "${RTL_CONF_FILE} + - RTL config file\n" \
        "+\n" \
        "${RTL_SERVICE_FILE} + - RTL systemd service file\n" \
        "+\n" \
        "${RTL_NGINX_SSL_CONF} + - RTL Nginx ssl config" | column -t -s "+"
echo
echo
echo -e "${LB}Open the RTL page in your browser via the following URL: ${NC}"
echo " https://${LOCAL_IP}:${RTL_SSL_PORT}"
echo -e "${LB}Login with your password defined above.${NC}"
echo

