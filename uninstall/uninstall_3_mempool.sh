#!/bin/bash


#
# config
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

#
# stop mempool service
#
echo
echo -e "${Y}Stop mempool service...${NC}"
systemctl stop "${MEMPOOL_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable mempool service
#
echo
echo -e "${Y}Disable mempool service...${NC}"
systemctl disable "${MEMPOOL_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete mempool service file
#
echo
echo -e "${Y}Deleting Mempool service file (${MEMPOOL_SERVICE_FILE})...${NC}"
rm "${MEMPOOL_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete mempool git download dir
#
echo
echo -e "${Y}Deleting Mempool dir in ${HOME_DIR}...${NC}"
rm -rf "${MEMPOOL_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete npm cache dir and .cache/Cypress dir)
#
echo
echo -e "${Y}Deleting npm cache dir...${NC}"
npm cache clean --force
rm -rf $(npm get cache)
rm -rf /root/.cache/Cypress
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete mempool maria-db database
#
echo
echo -e "${Y}Deleting Mempool maria-db databse (mempool)...${NC}"
mysql -e "drop database mempool;"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# nginx config files
#
echo
echo -e "${Y}Deleting Mempool nginx files...${NC}"
rm "${MEMPOOL_NGINX_SSL_CONF}"
rm "${MEMPOOL_NGINX_SNIPPET}"
rm /etc/nginx/sites-enabled/mempool-ssl.conf
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete mempool from nginx webroot dir
#
echo
echo -e "${Y}Deleting mempool webroot folder in /var/www/html/...${NC}"
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
echo -e "${Y}Un-installation all done!${NC}"
echo

