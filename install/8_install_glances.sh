#!/bin/bash

#
### download and install Glances (system monitoring tool)
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
echo -e "${Y}This script will download and install Glances...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Upgrade system to newest software (apt-get update / apt-get upgrade)"
echo "- Download Glances installation script into /tmp"
echo "- Set env var for pip externally-managed-environment error"
echo "- Install Glances via installation script"
echo "- Create nginx streams-enabled dir (if not existing))"
echo "- Create systemd ${GLANCES_SERVICE} service file for web service"
echo "- Create nginx Glances ssl config file"
echo "- Reload Niginx web server configs"
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
### download Glances installation script
#
echo
echo -e "${Y}Download Glances installation script into /tmp...${NC}"
cd "/tmp" || { echo "cd /tmp failed"; exit 1; }
# glances install script
wget -qO /tmp/install_glances.sh https://raw.githubusercontent.com/nicolargo/glancesautoinstall/master/install.sh
chmod +x /tmp/install_glances.sh
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### set environment variable for the pip externally-managed-environment error
#
echo
echo -e "${Y}Set environment variable for pip externally-managed-environment error...${NC}"
export PIP_BREAK_SYSTEM_PACKAGES=1
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### installation via install script
#
echo
echo -e "${Y}Install Glances via installer script...${NC}"
. /tmp/install_glances.sh
# delete install script after installation
rm -f /tmp/install_glances.sh
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### nginx Glances app config dir
#
echo
echo -e "${Y}Create nginx Glances streams-enabled dir...${NC}"
mkdir -p /etc/nginx/streams-enabled
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create Glances service file for web service
#
echo
echo -e "${Y}Create Glances systemd service file for web service...${NC}"
cat > "${GLANCES_SERVICE_FILE}"<< EOF
#
# Glances System Monitor web service file
#
[Unit]
Description=Glances
After=network.target

[Service]
ExecStart=/usr/local/bin/glances -w
User=${USER}
Group=${USER}
Restart=on-abort
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### nginx glances ssl config
#
echo
echo -e "${Y}Write nginx Glances ssl config file...${NC}"
cat > "${GLANCES_NGINX_SSL_CONF}"<< EOF
#
# Glances ssl conf, put into /etc/niginx/streams-enabled/glances-ssl.conf
#
upstream glances {
  server 127.0.0.1:61208;
}
server {
  listen ${GLANCES_SSL_PORT} ssl;
  listen [::]:${GLANCES_SSL_PORT} ssl;
  proxy_pass glances;
}
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### reload nginx configs
#
echo
echo -e "${Y}Reload Nginx configs...${NC}"
systemctl reload nginx
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### remove files/folders left from installation
#
echo
echo -e "${Y}Remove files/folders left from installation...${NC}"
rm -rf /root/.cache/pip
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Installation all done!${NC}"
echo
echo -e "${LB}Systemd Service (as root or with sudo as user):${NC}"
echo -e " systemctl enable ${GLANCES_SERVICE} + - enable Glances service after boot\n" \
       "systemctl start ${GLANCES_SERVICE} + - start Glances service\n" \
       "systemctl stop ${GLANCES_SERVICE} + - stop Glances service\n" \
       "systemctl status ${GLANCES_SERVICE} + - show Glances service status" | column -t -s "+"
echo
echo -e "${LB}View Log:${NC}"
echo " journalctl -fu ${GLANCES_SERVICE}"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${GLANCES_APP_DIR} + - Glances binary application\n" \
        "/etc/systemd/system/glances.service + - Glances systemd service file\n" \
        "/etc/nginx/streams-enabled/glances-ssl.conf + - Glances nginx ssl config" | column -t -s "+"
echo
echo -e "${LB}Glances can be called directly from the terminal or via web page.${NC}"
echo -e "${LB}In terminal just execute: ${NC}glances <enter>${NC}"
echo -e "${LB}For the web page start the service (see above) and access the url via web browser:${NC}"
echo " https://${LOCAL_IP}:${GLANCES_SSL_PORT}"
echo
echo -e "${LB}Documentation can be found here (e.g.: there are some keys which can be used to change display):${NC}"
echo " https://glances.readthedocs.io/en/latest/"
echo


