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
echo -e "${Y}This script will uninstall all files/folders of the Fulcrum installation...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Stop fulcrum systemd service (${FULCRUM_SERVICE})"
echo "- Disable fulcrum systemd service (${FULCRUM_SERVICE})"
echo "- Delete fulcrum systemd service file (${FULCRUM_SERVICE_FILE})"
echo "- Delete fulcrum download dir (${FULCRUM_DOWNLOAD_DIR})"
echo "- Delete fulcrum base dir (${FULCRUM_DIR})"
echo "- Delete fulcrum data dir (${FULCRUM_DATA_DIR})"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
# stop fulcrum service
#
echo
echo -e "${Y}Stop Fulcrum service (${FULCRUM_SERVICE})...${NC}"
systemctl stop "${FULCRUM_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable fulcrum service
#
echo
echo -e "${Y}Disable Fulcrum service (${FULCRUM_SERVICE})...${NC}"
systemctl disable "${FULCRUM_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete fulcrum service file
#
echo
echo -e "${Y}Delete fulcrum systemd service file (${FULCRUM_SERVICE_FILE})...${NC}"
rm -f "${FULCRUM_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------
#
# delete fulcrum download dir
#
echo
echo -e "${Y}Delete Fulcrum download dir (${FULCRUM_DOWNLOAD_DIR})...${NC}"
rm -rf "${FULCRUM_DOWNLOAD_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete fulcrum base dir
#
echo
echo -e "${Y}Delete Fulcrum base dir (${FULCRUM_DIR})...${NC}"
rm -rf "${FULCRUM_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete fulcrum data dir
#
echo
echo -e "${Y}Delete Fulcrum data dir (${FULCRUM_DATA_DIR})...${NC}"
rm -rf "${FULCRUM_DATA_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Uninstallation all done!${NC}"
echo
