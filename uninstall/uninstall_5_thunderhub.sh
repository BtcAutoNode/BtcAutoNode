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
echo -e "${Y}This script will uninstall all files/folders of the Thunderhub installation...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Stop thunderhub systemd service (${THH_SERVICE})"
echo "- Disable thunderhub systemd service (${THH_SERVICE})"
echo "- Delete thunderhub systemd service file (${THH_SERVICE_FILE})"
echo "- Delete thunderhub base dir (${THH_DIR})"
echo "- Delete thunderhub config dir (${THH_CONF_DIR})"
echo "- Delete thunderhub nginx config file (${THH_NGINX_SSL_CONF})"
echo "- Restart nginx web server"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
# stop thunderhub service
#
echo
echo -e "${Y}Stop Thunderhub service (${THH_SERVICE})...${NC}"
systemctl stop "${THH_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable thunderhub service
#
echo
echo -e "${Y}Disable Thunderhub service (${THH_SERVICE})...${NC}"
systemctl disable "${THH_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete thunderhub service file
#
echo
echo -e "${Y}Delete Thunderhub service file (${THH_SERVICE_FILE})...${NC}"
rm -f "${THH_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete thunderhub git download dir
#
echo
echo -e "${Y}Delete Thunderhub dir (${THH_DIR})...${NC}"
rm -rf "${THH_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete thunderhub config dir
#
echo
echo -e "${Y}Delete Thunderhub config dir (${THH_CONF_DIR})...${NC}"
rm -rf "${THH_CONF_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# nginx config file
#
echo
echo -e "${Y}Delete Thunderhub nginx file (${THH_NGINX_SSL_CONF})...${NC}"
rm -f "${THH_NGINX_SSL_CONF}"
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
