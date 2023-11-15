#!/bin/bash

#
### upgrade thunderhub (if possible)
#

# fail if a command fails and exit
set -e

#-----------------------------------------------------------------

#
### check if CONFIG file is there and not empty, otherwise exit
#
if [[ ! -f CONFIG || ! -s CONFIG ]] ; then
    echo '"CONFIG" file is not there or empty, exiting.'
    exit
fi

#-----------------------------------------------------------------

#
### Config
#
. CONFIG

#-----------------------------------------------------------------

#
### check if root, otherwise exit
#
if [ "$EUID" -ne 0 ]; then
  echo -e "${R}Please run the installation script as root!${NC}"
  exit
else
  # set PATH env var for sbin and bin dirs (su root fails the installation)
  export PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
fi

#-----------------------------------------------------------------

# clear screen
clear

#-----------------------------------------------------------------

#
### print info
#
echo
echo -e "${Y}This script will check for a new Thunderhub version and upgrade if possible...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Check latest Github version against current running version"
echo "- Exit if no new version is available"
echo "- Exit if Thunderhub service is still active"
echo "- Request user to confirm to upgrade to the new version (by user interaction)"
echo "- Update the Thunderhub release"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
### check for new version
#
echo
echo -e "${Y}Check Github version and compare to running version...${NC}"
latest_version=$(curl -sL https://github.com/apotdevin/thunderhub/releases/latest | grep "<title>Release" | cut -d ' ' -f 4 | cut -c2-)
running_version=$(cat ${THH_DIR}/package.json | jq -r ".version")
echo "Latest version on Github : ${latest_version}"
echo "Current version running  : ${running_version}"
echo
if [ "$latest_version" = "$running_version" ]; then
  echo -e "${R}No new version available...exiting${NC}"
  echo
  exit
else
  echo -e "${G}New version ${latest_version} available...possible to upgrade${NC}"
fi
# replace so existing commands can be used
THH_VERSION="${latest_version}"
latestrelease="v${THH_VERSION}"
#echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### check if thunderhub service is still active (exit if so)
#
if systemctl is-active --quiet "${THH_SERVICE}"; then
  echo -e "${R}Thunderhub service still running...exiting!${NC}"
  echo
  echo -e "${LB}Stop the service via:${NC}"
  echo " systemctl stop ${THH_SERVICE} (as root)"
  echo " sudo systemctl stop ${THH_SERVICE} (as satoshi)"
  echo
  exit
else
  echo -e "${G}Thunderhub service not running${NC}"
fi

#----------------------------------------------------------------

#
### ask to go on or exit
#
echo
echo -e "${LR}Do you really want to upgrade to the newer version??${NC}"
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
### update the thunderhub application
#
echo
echo -e "${Y}Update the Thunderhub application...${NC}"
echo -e "${LB}This can take several minutes!${NC}"
# update
git config --global --add safe.directory "${THH_DIR}"
cd "${THH_DIR}"
git fetch
git checkout "${latestrelease}"
# update npm
npm install -g npm@10.2.4
npm run build
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Upgrade all done!${NC}"
echo
echo -e "${LB}Start Thunderhub service again via:${NC}"
echo " systemctl start ${THH_SERVICE} (as root)"
echo " sudo systemctl start ${THH_SERVICE} (as satoshi)"
echo

