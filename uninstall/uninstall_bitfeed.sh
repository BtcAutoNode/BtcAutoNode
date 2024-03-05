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

#
# stop bitfeed service
#
echo
echo -e "${Y}Stop Bitfeed service...${NC}"
systemctl stop "${BITFEED_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable bitfeed service
#
echo
echo -e "${Y}Disable Bitfeed service...${NC}"
systemctl disable "${BITFEED_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete bitfeed service file
#
echo
echo -e "${Y}Deleting Bitfeed service file (${BITFEED_SERVICE_FILE})...${NC}"
rm "${BITFEED_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### uninstall dependencies
#
echo
echo -e "${Y}Uninstalling dependencies...${NC}"
for i in ${BITFEED_PKGS}; do
  echo -e "${LB}Uninstalling package ${i} ...${NC}"
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
echo -e "${Y}Deleting Bitfeed dir in ${HOME_DIR}...${NC}"
rm -rf "${BITFEED_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete npm cache dir and .cache/Cypress dir)
#
echo
echo -e "${Y}Deleting npm cache dir...${NC}"
npm cache clean --force
rm -rf $(npm get cache)
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# nginx config files
#
echo
echo -e "${Y}Deleting Bitfeed nginx files...${NC}"
rm "${BITFEED_NGINX_SSL_CONF}"
rm /etc/nginx/sites-enabled/bitfeed-ssl.conf
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete bitfeed from nginx webroot dir
#
echo
echo -e "${Y}Deleting Bitfeed webroot folder in /var/www/html/...${NC}"
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
echo -e "${Y}Un-installation all done!${NC}"
echo


