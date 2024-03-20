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
echo -e "${Y}This script will uninstall all files/folders of the LN-Visualizer installation...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Stop ln-visualizer systemd service (${LNVIS_SERVICE})"
echo "- Disable ln-visualizer systemd service (${LNVIS_SERVICE})"
echo "- Delete ln-visualizer systemd service file (${LNVIS_SERVICE_FILE})"
#echo "- Uninstall package dependencies via apt-get (${LNVIS_PKGS})"
echo "- Delete ln-visualizer base dir (${LNVIS_DIR})"
echo "- Delete ln-visualizer nginx config files (${LNVIS_NGINX_SSL_CONF} and sym link)"
echo "- Delete ln-visualizer nginx webroot dir (${LNVIS_WEBROOT_DIR})"
echo "- Restart nginx web server"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
# stop ln-visualizer service
#
echo
echo -e "${Y}Stop LN-Visualizer service (${LNVIS_SERVICE})...${NC}"
systemctl stop "${LNVIS_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable ln-visualizer service
#
echo
echo -e "${Y}Disable LN-Visualizer service (${LNVIS_SERVICE})...${NC}"
systemctl disable "${LNVIS_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete ln-visualizer service file
#
echo
echo -e "${Y}Delete LN-Visualizer service file (${LNVIS_SERVICE_FILE})...${NC}"
rm -f "${LNVIS_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### uninstall dependencies
#
#echo
#echo -e "${Y}Uninstall dependencies...${NC}"
#for i in ${LNVIS_PKGS}; do
#  echo -e "${LB}Uninstall package ${i} ...${NC}"
#  apt-get -q remove -y "${i}"
#  echo -e "${LB}Done.${NC}"
#done
#apt-get -q autoremove -y
#echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete ln-visualizer git download dir
#
echo
echo -e "${Y}Delete LN-Visualizer dir (${LNVIS_DIR})...${NC}"
rm -rf "${LNVIS_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# nginx config files
#
echo
echo -e "${Y}Delete LN-Visualizer nginx files...${NC}"
rm -f "${LNVIS_NGINX_SSL_CONF}"
rm -f /etc/nginx/sites-enabled/ln-visualizer-ssl.conf
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete ln-visualizer from nginx webroot dir
#
echo
echo -e "${Y}Delete LN-Visualizer webroot dir (${LNVIS_WEBROOT_DIR})...${NC}"
rm -rf "${LNVIS_WEBROOT_DIR}"
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

