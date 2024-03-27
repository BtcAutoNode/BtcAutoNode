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
### config
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
echo -e "${Y}This script will uninstall all files/folders of the Sparrow installation...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Kill tmux sparrow session (sparrow_server)"
echo "- Delete sparrow download dir (${SPARROW_DOWNLOAD_DIR})"
echo "- Delete sparrow base dir (${SPARROW_DIR})"
echo "- Delete sparrow app dir (${SPARROW_APP_DIR})"
echo "- Delete sparrow symlink (${SPARROW_SYM_LINK})"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
### kill tmux sparrow session
#
echo
echo -e "${Y}Kill tmux Sparrow session (sparrow_server)...${NC}"
su -c 'tmux kill-session -t sparrow_server 2>/dev/null' "${USER}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### delete sparrow download dir
#
echo
echo -e "${Y}Delete Sparrow download dir (${SPARROW_DOWNLOAD_DIR})...${NC}"
rm -rf "${SPARROW_DOWNLOAD_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### delete sparrow base dir
#
echo
echo -e "${Y}Delete Sparrow base dir (${SPARROW_DIR})...${NC}"
rm -rf "${SPARROW_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### delete sparrow application directory
#
echo
echo -e "${Y}Delete Sparrow app dir (${SPARROW_APP_DIR})...${NC}"
rm -rf "${SPARROW_APP_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### delete sparrow symlink in /urs/local/bin
#
echo
echo -e "${Y}Delete Sparrow symbolic link (${SPARROW_SYM_LINK})...${NC}"
rm -f "${SPARROW_SYM_LINK}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Uninstallation all done!${NC}"
echo
