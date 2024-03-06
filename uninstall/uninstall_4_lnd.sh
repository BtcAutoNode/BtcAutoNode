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
echo -e "${Y}This script will uninstall all files/folders of the LND installation...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Stop lnd systemd service (${LND_SERVICE})"
echo "- Disable lnd systemd service (${LND_SERVICE})"
echo "- Delete lnd systemd service file (${LND_SERVICE_FILE})"
echo "- Delete lnd download dir (${LND_DOWNLOAD_DIR})"
echo "- Delete lnd base dir (${LND_DIR})"
echo "- Delete lnd app binaries from /usr/local/bin"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
# stop lnd service
#
echo
echo -e "${Y}Stop Lnd service (${LND_SERVICE})...${NC}"
systemctl stop "${LND_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable Lnd service
#
echo
echo -e "${Y}Disable Lnd service (${LND_SERVICE})...${NC}"
systemctl disable "${LND_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete Lnd service file
#
echo
echo -e "${Y}Delete Lnd systemd service file (${LND_SERVICE_FILE})...${NC}"
rm -f "${LND_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------
#
# delete Lnd download dir
#
echo
echo -e "${Y}Delete Lnd download dir (${LND_DOWNLOAD_DIR})...${NC}"
rm -rf "${LND_DOWNLOAD_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete Lnd dir
#
echo
echo -e "${Y}Delete Lnd base dir (${LND_DIR})...${NC}"
rm -rf "${LND_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete Lnd apps from /usr/local/bin
#
echo
echo -e "${Y}Delete Lnd apps from /usr/local/bin...${NC}"
rm -f "/usr/local/bin/lnd"
rm -f "/usr/local/bin/lncli"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Uninstallation all done!${NC}"
echo
