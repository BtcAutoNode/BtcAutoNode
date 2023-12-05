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
# stop lnd service
#
echo
echo -e "${Y}Stop Lnd service...${NC}"
systemctl stop "${LND_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable Lnd service
#
echo
echo -e "${Y}Disable Lnd service...${NC}"
systemctl disable "${LND_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete Lnd download dir
#
echo
echo -e "${Y}Delete Lnd download dir...${NC}"
rm -rf "${LND_DOWNLOAD_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete Lnd dir
#
echo
echo -e "${Y}Delete Lnd base dir...${NC}"
rm -rf "${LND_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete Lnd service file
#
echo
echo -e "${Y}Delete Lnd systemd service file...${NC}"
rm "${LND_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete Lnd apps from /usr/local/bin
#
echo
echo -e "${Y}Delete Lnd apps from /usr/local/bin...${NC}"
rm "/usr/local/bin/lnd"
rm "/usr/local/bin/lncli"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Un-installation all done!${NC}"
echo

