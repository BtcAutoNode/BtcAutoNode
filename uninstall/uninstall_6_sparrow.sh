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
source CONFIG

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
### delete sparrow download dir
#
echo
echo -e "${Y}Delete sparrow download dir...${NC}"
rm -rf "${SPARROW_DOWNLOAD_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### delete sparrow base dir
#
echo
echo -e "${Y}Delete user sparrow base dir...${NC}"
rm -rf "${SPARROW_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### delete sparrow application directory
#
echo
echo -e "${Y}Delete sparrow application dir in /opt...${NC}"
rm -rf "${SPARROW_APP_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### delete sparrow symlink in /urs/local/bin
#
echo
echo -e "${Y}Delete sparrow symbolic link in /usr/local/bin...${NC}"
rm -rf "${SPARROW_SYM_LINK}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Un-installation all done!${NC}"
echo

