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
# stop explorer service
#
echo
echo -e "${Y}Stop Explorer service...${NC}"
systemctl stop "${EXPLORER_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable explorer service
#
echo
echo -e "${Y}Disable Explorer service...${NC}"
systemctl disable "${EXPLORER_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete explorer service file
#
echo
echo -e "${Y}Deleting Explorer service file (${EXPLORER_SERVICE_FILE})...${NC}"
rm "${EXPLORER_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete explorer git download dir
#
echo
echo -e "${Y}Deleting Explorer dir in ${HOME_DIR}...${NC}"
rm -rf "${EXPLORER_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# nginx config file
#
echo
echo -e "${Y}Deleting Explorer nginx config...${NC}"
rm "${EXPLORER_NGINX_SSL_CONF}"
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


