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
echo -e "${Y}This script will uninstall all files/folders of the RTL installation...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Stop RTL systemd service (${RTL_SERVICE})"
echo "- Disable RTL systemd service (${RTL_SERVICE})"
echo "- Delete RTL systemd service file (${RTL_SERVICE_FILE})"
echo "- Delete RTL base dir (${RTL_DIR})"
echo "- Delete RTL nginx ssl config (${RTL_NGINX_SSL_CONF})"
echo "- Restart nginx web server"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
# stop rtl service
#
echo
echo -e "${Y}Stop RTL service (${RTL_SERVICE})...${NC}"
systemctl stop "${RTL_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable rtl service
#
echo
echo -e "${Y}Disable RTL service (${RTL_SERVICE})...${NC}"
systemctl disable "${RTL_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete rtl service file
#
echo
echo -e "${Y}Delete RTL systemd service file (${RTL_SERVICE_FILE})...${NC}"
rm -f "${RTL_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete rtl base dir
#
echo
echo -e "${Y}Delete RTL base dir (${RTL_DIR})...${NC}"
rm -rf "${RTL_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# nginx config file
#
echo
echo -e "${Y}Delete RTL nginx config (${RTL_NGINX_SSL_CONF})...${NC}"
rm -f "${RTL_NGINX_SSL_CONF}"
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

