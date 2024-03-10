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
echo -e "${Y}This script will uninstall all files/folders of the Mempool installation...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Stop mempool systemd service (${MEMPOOL_SERVICE})"
echo "- Disable mempool systemd service (${MEMPOOL_SERVICE})"
echo "- Delete mempool systemd service file (${MEMPOOL_SERVICE_FILE})"
echo "- Delete mempool base dir (${MEMPOOL_DIR})"
echo "- Delete mempool maria-db database (db mempool)"
echo "- Delete mempool nginx config files"
echo "- Delete mempool from nginx webroot dir (${MEMPOOL_WEBROOT_DIR})"
echo "- Restart nginx web server"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
# stop mempool service
#
echo
echo -e "${Y}Stop Mempool service (${MEMPOOL_SERVICE})...${NC}"
systemctl stop "${MEMPOOL_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable mempool service
#
echo
echo -e "${Y}Disable Mempool service (${MEMPOOL_SERVICE})...${NC}"
systemctl disable "${MEMPOOL_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete mempool service file
#
echo
echo -e "${Y}Delete Mempool service file (${MEMPOOL_SERVICE_FILE})...${NC}"
rm -f "${MEMPOOL_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete mempool git download dir
#
echo
echo -e "${Y}Delete Mempool dir (${MEMPOOL_DIR})...${NC}"
rm -rf "${MEMPOOL_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete mempool maria-db/mysql database
#
echo
echo -e "${Y}Delete Mempool maria-db/mysql database (db mempool)...${NC}"
mysql -e "drop database mempool;"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# nginx config files
#
echo
echo -e "${Y}Delete Mempool nginx files...${NC}"
rm -f "${MEMPOOL_NGINX_SSL_CONF}"
rm -f "${MEMPOOL_NGINX_APP_CONF}"
rm -f /etc/nginx/sites-enabled/mempool-ssl.conf
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete mempool from nginx webroot dir
#
echo
echo -e "${Y}Delete Mempool webroot folder in /var/www/html/...${NC}"
rm -rf "${MEMPOOL_WEBROOT_DIR}"
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
