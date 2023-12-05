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
# stop bisq xpra server
#
echo
echo -e "${Y}Stop bisq xpra server...${NC}"
su -c '${eval ${BISQ_STOP_SCRIPT}' ${USER}
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# stop bisq gradle server(s) running
#
echo
echo -e "${Y}Stop bisq xpra server...${NC}"
gradle --stop
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete bisq dir
#
echo
echo -e "${Y}Delete bisq app dir...${NC}"
rm -rf "${BISQ_APP_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete bisq data dir
#
echo
echo -e "${Y}Delete bisq data dir...${NC}"
rm -rf "${BISQ_DATA_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete bisq download dir
#
echo
echo -e "${Y}Delete bisq dir...${NC}"
rm -rf "${BISQ_DOWNLOAD_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete bisq start and stop script files
#
echo
echo -e "${Y}Delete bisq start and stop script files...${NC}"
rm -rf "${BISQ_START_SCRIPT}"
rm -rf "${BISQ_STOP_SCRIPT}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete .gradle dir in users home dir
#
echo
echo -e "${Y}Delete .gradle dir in ${USER} home dir...${NC}"
rm -rf "${HOME_DIR}/.gradle"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete .xpra dir in users home dir
#
echo
echo -e "${Y}Delete .xpra dir in ${USER} home dir...${NC}"
rm -rf "${HOME_DIR}/.xpra"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# uninstall xpra via apt
#
echo
echo -e "${Y}Uninstall xpra via apt...${NC}"
apt -y purge xpra
# autoremoving packages and cleaning apt data
echo -e "${LB}aAutoremoving packages and cleaning apt data...${NC}"
apt -y autoremove && apt -y clean
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Un-installation all done!${NC}"
echo

