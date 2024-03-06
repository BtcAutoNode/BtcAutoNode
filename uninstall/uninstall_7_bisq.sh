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
echo -e "${Y}This script will uninstall all files/folders of the Bisq installation...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Stop bisq xpra server via stop script"
echo "- Stop bisq gradle server(s)"
echo "- Delete bisq download dir (${BISQ_DOWNLOAD_DIR})"
echo "- Delete bisq app dir (${BISQ_APP_DIR})"
echo "- Delete bisq data dir (${BISQ_DATA_DIR})"
echo "- Delete bisq start/stop script files in ${HOME_DIR}"
echo "- Delete .gradle dir in ${HOME_DIR}"
echo "- Delete .xpra dir in ${HOME_DIR}"
echo "- Uninstall xpra package via apt-get"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
# stop bisq xpra server
#
echo
echo -e "${Y}Stop Bisq xpra server...${NC}"
su -c ${BISQ_STOP_SCRIPT} ${USER}
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# stop bisq gradle server(s) running
#
echo
echo -e "${Y}Stop Bisq gradle server...${NC}"
su -c ${BISQ_APP_DIR}'/./gradlew --stop' ${USER}
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete bisq download dir
#
echo
echo -e "${Y}Delete Bisq download dir (${BISQ_DOWNLOAD_DIR})...${NC}"
rm -rf "${BISQ_DOWNLOAD_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete bisq app dir
#
echo
echo -e "${Y}Delete Bisq app dir (${BISQ_APP_DIR})...${NC}"
rm -rf "${BISQ_APP_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete bisq data dir
#
echo
echo -e "${Y}Delete Bisq data dir (${BISQ_DATA_DIR})...${NC}"
rm -rf "${BISQ_DATA_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete bisq start and stop script files
#
echo
echo -e "${Y}Delete bisq start and stop script files...${NC}"
rm -f "${BISQ_START_SCRIPT}"
rm -f "${BISQ_STOP_SCRIPT}"
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
echo -e "${LB}Autoremoving packages and cleaning apt data...${NC}"
apt -y autoremove && apt -y clean
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Uninstallation all done!${NC}"
echo
