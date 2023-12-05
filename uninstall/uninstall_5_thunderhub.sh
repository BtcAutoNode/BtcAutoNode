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
# stop thunderbird service
#
echo
echo -e "${Y}Stop Thunderhub service...${NC}"
systemctl stop "${THH_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable thunderhub service
#
echo
echo -e "${Y}Disable Thunderhub service...${NC}"
systemctl disable "${THH_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete thunderhub service file
#
echo
echo -e "${Y}Deleting Thunderhub service file (${THH_SERVICE_FILE})...${NC}"
rm "${THH_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete thunderhub git download dir
#
echo
echo -e "${Y}Deleting Thunderhub dir in ${HOME_DIR}...${NC}"
rm -rf "${THH_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete thunderhub config dir
#
echo
echo -e "${Y}Deleting Thunderhub config dir in ${HOME_DIR}...${NC}"
rm -rf "${THH_CONF_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# nginx config file
#
echo
echo -e "${Y}Deleting Thunderhub nginx files...${NC}"
rm "${THH_NGINX_SSL_CONF}"
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

