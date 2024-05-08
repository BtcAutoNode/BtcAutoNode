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
echo -e "${Y}This script will uninstall all files/folders of the Electrs installation...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Stop electrs systemd service (${ELECTRS_SERVICE})"
echo "- Disable electrs systemd service (${ELECTRS_SERVICE})"
echo "- Delete electrs systemd service file (${ELECTRS_SERVICE_FILE})"
echo "- Uninstall dependencies with apt (${ELECTRS_PKGS})"
echo "- Uninstall rust via rustup script"
echo "- Delete electrs base dir (${ELECTRS_DIR})"
echo "- Delete electrs data dir (${ELECTRS_DATA_DIR})"
echo "- Delete electrs binary in /usr/local/bin"
echo "- Delete electrs nginx ssl config (${ELECTRS_NGINX_SSL_CONF})"
echo "- Restart nginx web server"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
# stop electrs service
#
echo
echo -e "${Y}Stop Electrs service (${ELECTRS_SERVICE})...${NC}"
systemctl stop "${ELECTRS_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable electrs service
#
echo
echo -e "${Y}Disable Electrs service (${ELECTRS_SERVICE})...${NC}"
systemctl disable "${ELECTRS_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete electrs service file
#
echo
echo -e "${Y}Delete Electrs systemd service file (${ELECTRS_SERVICE_FILE})...${NC}"
rm -f "${ELECTRS_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### uninstall dependencies
#
echo
echo -e "${Y}Uninstall dependencies...${NC}"
for i in ${ELECTRS_PKGS}; do
  echo -e "${LB}Uninstall package ${i} ...${NC}"
  apt-get -q remove -y "${i}"
  echo -e "${LB}Done.${NC}"
done
apt-get -q autoremove -y
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete electrs base dir
#
echo
echo -e "${Y}Delete Electrs base dir (${ELECTRS_DIR})...${NC}"
rm -rf "${ELECTRS_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete electrs data dir
#
echo
echo -e "${Y}Delete Electrs data dir (${ELECTRS_DATA_DIR})...${NC}"
rm -rf "${ELECTRS_DATA_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete electrs binary in /usr/local/bin
#
echo
echo -e "${Y}Delete Electrs binary in /usr/local/bin...${NC}"
rm -rf /usr/local/bin/electrs
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# nginx config file
#
echo
echo -e "${Y}Delete Electrs nginx config (${ELECTRS_NGINX_SSL_CONF})...${NC}"
rm -f "${ELECTRS_NGINX_SSL_CONF}"
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

