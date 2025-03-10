#!/bin/bash

#
### check if CONFIG file is there and not empty, otherwise exit
#
if [[ ! -f CONFIG || ! -s CONFIG ]] ; then
    echo '"CONFIG" file is not there or empty, exiting.'
    exit
fi

#-----------------------------------------------------------------

#
# config
#
. CONFIG

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
### Check if user really wants to uninstall...or exit
#
echo
echo -e "${Y}This script will uninstall all files/folders of the Uptime Kuma installation...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Stop Uptime Kuma systemd service (${KUMA_SERVICE})"
echo "- Disable Uptime Kuma systemd service (${KUMA_SERVICE})"
echo "- Delete Uptime Kuma systemd service file (${KUMA_SERVICE_FILE})"
echo "- Delete Uptime Kuma base dir (${KUMA_DIR})"
echo "- Delete Uptime Kuma nginx config file (${KUMA_NGINX_SSL_CONF})"
echo "- Delete Uptime Kuma nginx link to config file (${KUMA_NGINX_SSL_CONF_LINK})"
echo "- Restart nginx web server"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
# stop uptime-kuma service
#
echo
echo -e "${Y}Stop Uptime Kuma service (${KUMA_SERVICE})...${NC}"
systemctl stop "${KUMA_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable uptime-kuma service
#
echo
echo -e "${Y}Disable Uptime Kuma service (${KUMA_SERVICE})...${NC}"
systemctl disable "${KUMA_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete uptime-kuma service file
#
echo
echo -e "${Y}Delete Uptime Kuma service file (${KUMA_SERVICE_FILE})...${NC}"
rm -f "${KUMA_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete uptime-kuma git download dir
#
echo
echo -e "${Y}Delete Uptime Kuma base dir (${KUMA_DIR})...${NC}"
rm -rf "${KUMA_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete uptime-kuma nginx config file
#
echo
echo -e "${Y}Delete Uptime Kuma nginx ssl config file (${KUMA_NGINX_SSL_CONF})...${NC}"
rm -f "${KUMA_NGINX_SSL_CONF}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete uptime-kuma nginx link to config file
#
echo
echo -e "${Y}Delete Uptime Kuma nginx ssl config file link (${KUMA_NGINX_SSL_CONF_LINK})...${NC}"
rm -f "${KUMA_NGINX_SSL_CONF_LINK}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# restart nginx
#
echo
echo -e "${Y}Restart Nginx...${NC}"
systemctl restart nginx
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Uninstallation all done!${NC}"
echo

