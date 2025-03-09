#!/bin/bash

#
### download, install Uptime Kuma (easy-to-use self-hosted monitoring tool)
### Github: https://github.com/louislam/uptime-kuma
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
echo -e "${Y}This script will download and install Uptime-Kuma...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Upgrade system to newest software (apt-get update / apt-get upgrade)"
echo "- Clone Uptime Kuma Github repository, version ${KUMA_VERSION}"
echo "- Build the Uptime Kuma application"
echo "- Clean up npm caches from build (/root/.cache)"
echo "- Change permissions of Uptime Kuma base dir (${KUMA_DIR}) for user ${USER}"
echo "- Create systemd ${KUMA_SERVICE_FILE} service file"
echo "- Create Uptime Kuma nginx ssl config (${KUMA_NGINX_SSL_CONF})"
echo "- Create Uptime Kuma nginx link to ssl config (${KUMA_NGINX_SSL_CONF_LINK})"
echo "- Check nginx and restart nginx web server"
echo "- Remove npm installation leftover in root dir (/root/.npm))"
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
### cd into homedir and download uptime-kuma git repository as user satoshi in /home/satoshi
#
echo
echo -e "${Y}Cd into ${HOME_DIR} and clone Uptime Kuma git repository into ${KUMA_DIR}...${NC}"
cd "${HOME_DIR}"
# delete dir if exist
rm -rf "${KUMA_DIR}"
git clone https://github.com/louislam/uptime-kuma
cd "${KUMA_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### get the latest release version from github and checkout git there
#
echo
echo -e "${Y}Get latest release version and git checkout at this release...${NC}"
#latestrelease=$(curl -sL https://github.com/louislam/uptime-kuma/releases/latest | grep "<title>Release" | cut -d ' ' -f 4)
latestrelease="${KUMA_VERSION}"
git -c advice.detachedHead=false checkout "${latestrelease}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### build the uptime-kuma application
#
echo
echo -e "${Y}Build the Uptime Kuma application...${NC}"
# set config
npm config set registry=https://registry.npmjs.com/
# update npm (based on warnings)
npm install -g npm@"${NPM_UPD_VER}"
# build
npm run setup
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### clean up npm caches from build
#
echo
echo -e "${Y}Clean npm caches from build...${NC}"
# clean the npm cache and delete npm cache dir
npm cache clean --force
rm -rf "$(npm get cache)"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permissions of the /home/satoshi/uptime-kuma dir to user satoshi
#
echo
echo -e "${Y}Change permissions of ${KUMA_DIR} to user ${USER}...${NC}"
chown -R "${USER}":"${USER}" "${KUMA_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create systemd service for for uptime-kuma
#
echo
echo -e "${Y}Create systemd service file for Uptime Kuma (${KUMA_SERVICE_FILE})...${NC}"
cat > "${KUMA_SERVICE_FILE}"<< EOF
[Unit]
Description=Uptime-Kuma - A free and open source uptime monitoring solution
Documentation=https://github.com/louislam/uptime-kuma
After=network.target

[Service]
Type=simple
User=${USER}
Group=${USER}
WorkingDirectory=${KUMA_DIR}
ExecStart=/usr/bin/npm run start-server
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### nginx uptime-kuma ssl config
#
echo
echo -e "${Y}Write Uptime Kuma nginx ssl config file (${KUMA_NGINX_SSL_CONF})...${NC}"
cat > "${KUMA_NGINX_SSL_CONF}"<< EOF
server {
    listen ${KUMA_SSL_PORT} ssl;
    listen [::]:${KUMA_SSL_PORT} ssl;
    server_name _;

    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
    ssl_session_timeout 4h;
    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers on;

  location / {
    proxy_set_header   X-Real-IP \$remote_addr;
    proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header   Host \$host;
    proxy_pass         http://localhost:3001/;
    proxy_http_version 1.1;
    proxy_set_header   Upgrade \$http_upgrade;
    proxy_set_header   Connection "upgrade";
  }
}
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create symbolic link from /etc/nginx/sites-available to sites-enabled
#
echo
echo -e "${Y}Create symbolic link for uptime-kuma-ssl.conf (${KUMA_NGINX_SSL_CONF_LINK})...${NC}"
ln -sf "${KUMA_NGINX_SSL_CONF}" "${KUMA_NGINX_SSL_CONF_LINK}"
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
### restart nginx webserver
#
echo
echo -e "${Y}Restart Nginx web server...${NC}"
systemctl restart nginx
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### remove npm installation left-over in /root/.npm
#
echo
echo -e "${Y}Remove npm installation left-over in /root/.npm...${NC}"
rm -rf /root/.npm
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Installation all done!${NC}"
echo
echo -e "${LB}Systemd Service (as root or with sudo as user):${NC}"
echo -e " systemctl enable ${KUMA_SERVICE} - enable service after boot\n" \
        "systemctl start ${KUMA_SERVICE}  - start Uptime Kuma service\n" \
        "systemctl stop ${KUMA_SERVICE}   - stop Uptime Kuma service\n" \
        "systemctl status ${KUMA_SERVICE} - show service status" | column -t -s "+"
echo
echo -e "${LB}View Log (as root or with sudo as user):${NC}"
echo " journalctl -fu ${KUMA_SERVICE}"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${KUMA_DIR} + - Uptime Kuma base directory\n" \
        "+\n" \
        "${KUMA_SERVICE_FILE} + - Uptime Kuma systemd service file\n" \
        "+\n" \
        "${KUMA_NGINX_SSL_CONF} + - Uptime Kuma nginx ssl config\n" \
        "${KUMA_NGINX_SSL_CONF_LINK} + - Uptime Kuma nginx ssl config link" | column -t -s "+"
echo
echo
echo -e "${LB}Open the Uptime Kuma page in your browser via the following URL: ${NC}"
echo " https://${LOCAL_IP}:${KUMA_SSL_PORT}"
echo -e "${LB}Create an user and start creating service monitors on the dashboard and create a status page from these.${NC}"
echo
echo -e "${LB}...or...${NC}"
echo
echo -e "${LB}Use a predefined Uptime Kuma database file containing 3 service monitors (bitcoind, fulcrum, mempool) and an example status page:${NC}"
echo
echo -e " ${LB}Start Uptime Kuma service to create the ${NC}data${LB} dir (${NC}sudo systemctl start uptime-kuma.service${LB}) in ${NC}${KUMA_DIR}"
echo -e " ${LB}Stop Uptime Kuma service again (${NC}sudo systemctl stop uptime-kuma.service${LB})${NC}"
echo
echo -e " ${LB}Download the ${NC}kuma.db${LB} file from the ${NC}res/uptime-kuma${LB} folder of the repository (or copy from cloned btcautonode dir))${NC}"
echo -e " ${LB}Copy the ${NC}kuma.db${LB} file over to the ${NC}${KUMA_DIR}/data${LB} directory overwriting the existing file.${NC}"
echo -e " ${LB}(Make sure that the file is owned by user ${USER} if copied over as root! (${NC}chown ${USER}:${USER} <file>${LB}))${NC}"
echo
echo -e " ${LB}Start the Uptime Kuma service again and login with the user provided below:${NC}"
echo -e " ${LB}User: ${NC}btcautonode / yPH71nkZz7LonCYj"
echo -e " ${LB}(Change the password in the page's settings menu after 1st login !!')${NC}"
echo -e " ${LB}URL Example Status Page: ${NC}https://${LOCAL_IP}:${KUMA_SSL_PORT}/status/btcautonode"
echo
echo -e " ${LB}(Use this as an example to see how to add other services. User cannot be changed...maybe in a future version.)${NC}"
echo -e " ${LB}(To start from scratch: stop service, delete the kuma.db file, start service and register your new user.)${NC}"
echo
echo -e "${LB}Guide for notifications (e.g. into a Telegram channel: ${NC}https://community.netcup.com/en/tutorials/uptime-kuma-notification-setup)"
echo

