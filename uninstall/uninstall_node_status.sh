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
echo -e "${Y}This script will uninstall all files/folders of the node_status installation...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Stop node_status systemd service (${NODE_STAT_SERVICE})"
echo "- Disable node_status systemd service (${NODE_STAT_SERVICE})"
echo "- Delete node_status systemd service file (${NODE_STAT_SERVICE_FILE})"
echo "- Uninstall package dependencies via apt-get (${NODE_STAT_PKGS})"
echo "- Delete node_status nginx config files (${NODE_STAT_NGINX_SSL_CONF} + sym-link)"
echo "- Delete node_status nginx webroot dir (${NODE_STAT_WEBROOT_DIR})"
echo "- Delete php-fpm config file (${NODE_STAT_FPM_CONF_FILE})"
echo "- Restart nginx web server"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
# stop node_status service
#
echo
echo -e "${Y}Stop node_status service (${NODE_STAT_SERVICE})...${NC}"
systemctl stop "${NODE_STAT_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable node_status service
#
echo
echo -e "${Y}Disable node_status service (${NODE_STAT_SERVICE})...${NC}"
systemctl disable "${NODE_STAT_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete node_status service file
#
echo
echo -e "${Y}Delete node_status service file (${NODE_STAT_SERVICE_FILE})...${NC}"
rm -f "${NODE_STAT_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### uninstall dependencies
#
echo
echo -e "${Y}Uninstall dependencies...${NC}"
for i in ${NODE_STAT_PKGS}; do
  echo -e "${LB}Uninstall package ${i} ...${NC}"
  apt-get -q remove -y "${i}"
  echo -e "${LB}Done.${NC}"
done
apt-get -q autoremove -y
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete nginx config files
#
echo
echo -e "${Y}Delete node_status nginx files...${NC}"
rm -f "${NODE_STAT_NGINX_SSL_CONF}"
# delete sym-link
rm -f /etc/nginx/sites-enabled/node_status-ssl.conf
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete node_status from nginx webroot dir
#
echo
echo -e "${Y}Delete node_status webroot dir (${NODE_STAT_WEBROOT_DIR})...${NC}"
rm -rf "${NODE_STAT_WEBROOT_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete php-fpm config file (${NODE_STAT_FPM_CONF_FILE})
#
echo
echo -e "${Y}Delete node_status php-fpm config file (${NODE_STAT_FPM_CONF_FILE})...${NC}"
rm -f "${NODE_STAT_FPM_CONF_FILE}"
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

