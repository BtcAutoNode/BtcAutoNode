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
# stop Fulcrum service
#
echo
echo -e "${Y}Stop Fulcrum service...${NC}"
systemctl stop "${FULCRUM_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable Fulcrum service
#
echo
echo -e "${Y}Disable Fulcrum service...${NC}"
systemctl disable "${FULCRUM_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete Fulcrum download dir
#
echo
echo -e "${Y}Delete Fulcrum download dir...${NC}"
rm -rf "${FULCRUM_DOWNLOAD_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete Fulcrum dir
#
echo
echo -e "${Y}Delete Fulcrum base dir...${NC}"
rm -rf "${FULCRUM_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete Fulcrum data dir
#
echo
echo -e "${Y}Delete Fulcrum data dir...${NC}"
rm -rf "${FULCRUM_DATA_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete Fulcrum service file
#
echo
echo -e "${Y}Delete fulcrum systemd service file...${NC}"
rm "${FULCRUM_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Un-installation all done!${NC}"
echo

