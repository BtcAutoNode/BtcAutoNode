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
echo -e "${Y}This script will uninstall all files/folders of the BTC-RPC-Explorer installation...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Stop explorer systemd service (${EXPLORER_SERVICE})"
echo "- Disable explorer systemd service (${EXPLORER_SERVICE})"
echo "- Delete explorer systemd service file (${EXPLORER_SERVICE_FILE})"
echo "- Delete explorer base dir (${EXPLORER_DIR})"
echo "- Delete explorer nginx config file (${EXPLORER_NGINX_SSL_CONF})"
echo "- Restart nginx web server"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
# stop explorer service
#
echo
echo -e "${Y}Stop Explorer service (${EXPLORER_SERVICE})...${NC}"
systemctl stop "${EXPLORER_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable explorer service
#
echo
echo -e "${Y}Disable Explorer service (${EXPLORER_SERVICE})...${NC}"
systemctl disable "${EXPLORER_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete explorer service file
#
echo
echo -e "${Y}Delete Explorer service file (${EXPLORER_SERVICE_FILE})...${NC}"
rm -f "${EXPLORER_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete explorer git download dir
#
echo
echo -e "${Y}Delete Explorer base dir (${EXPLORER_DIR})...${NC}"
rm -rf "${EXPLORER_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# nginx config file
#
echo
echo -e "${Y}Delete Explorer nginx config (${EXPLORER_NGINX_SSL_CONF})...${NC}"
rm -f "${EXPLORER_NGINX_SSL_CONF}"
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
