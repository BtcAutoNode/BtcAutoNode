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
echo -e "${Y}This script will uninstall all files/folders of the Bitfeed installation...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Stop bitfeed systemd service (${BITFEED_SERVICE})"
echo "- Disable bitfeed systemd service (${BITFEED_SERVICE})"
echo "- Delete bitfeed systemd service file (${BITFEED_SERVICE_FILE})"
echo "- Uninstall package dependencies via apt-get (${BITFEED_PKGS})"
echo "- Delete bitfeed base dir (${BITFEED_DIR})"
echo "- Delete bitfeed nginx config files"
echo "- Delete bitfeed nginx webroot dir (${BITFEED_WEBROOT_DIR})"
echo "- Restart nginx web server"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
# stop bitfeed service
#
echo
echo -e "${Y}Stop Bitfeed service (${BITFEED_SERVICE})...${NC}"
systemctl stop "${BITFEED_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable bitfeed service
#
echo
echo -e "${Y}Disable Bitfeed service (${BITFEED_SERVICE})...${NC}"
systemctl disable "${BITFEED_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete bitfeed service file
#
echo
echo -e "${Y}Delete Bitfeed service file (${BITFEED_SERVICE_FILE})...${NC}"
rm -f "${BITFEED_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### uninstall dependencies
#
echo
echo -e "${Y}Uninstall dependencies...${NC}"
for i in ${BITFEED_PKGS}; do
  echo -e "${LB}Uninstall package ${i} ...${NC}"
  apt-get -q remove -y "${i}"
  echo -e "${LB}Done.${NC}"
done
apt-get -q autoremove -y
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete bitfeed git download dir
#
echo
echo -e "${Y}Delete Bitfeed dir (${BITFEED_DIR})...${NC}"
rm -rf "${BITFEED_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# nginx config files
#
echo
echo -e "${Y}Delete Bitfeed nginx files...${NC}"
rm -f "${BITFEED_NGINX_SSL_CONF}"
rm -f /etc/nginx/sites-enabled/bitfeed-ssl.conf
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete bitfeed from nginx webroot dir
#
echo
echo -e "${Y}Delete Bitfeed webroot dir (${BITFEED_WEBROOT_DIR})...${NC}"
rm -rf "${BITFEED_WEBROOT_DIR}"
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
