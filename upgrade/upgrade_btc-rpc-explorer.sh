#!/bin/bash

#
### upgrade btc-rpc-explorer (if possible)
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
else
  # set PATH env var for sbin and bin dirs (su root fails the installation)
  export PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
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
fi

#-----------------------------------------------------------------

# clear screen
clear

#-----------------------------------------------------------------

#
### print info
#
echo
echo -e "${Y}This script will check for a new BTC-RPC-Explorer version and upgrade if possible...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Check latest Github version against current running version"
echo "- Exit if no new version is available"
echo "- Exit if BTC-RPC-Explorer service is still active"
echo "- Request user to confirm to upgrade to the new version (by user interaction)"
echo "- Update the BTC-RPC-Explorer release"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
### check for new version
#
echo
echo -e "${Y}Check Github version and compare to running version...${NC}"
latest_version=$(curl -sL https://github.com/janoside/btc-rpc-explorer/releases/latest | grep "<title>Release" | cut -d ' ' -f 4 | cut -c2-)
running_version=$(jq -r ".version" "${EXPLORER_DIR}"/package.json)
echo "Latest version on Github : ${latest_version}"
echo "Current version running  : ${running_version}"
echo

# check if a version string is empty . If so, exit script
if [ "$latest_version" = "" ]; then
  echo -e "${R}Latest version not available...exiting. Github page not reachable?${NC}"
  echo
  exit 1
elif [ "$running_version" = "" ]; then
  echo -e "${R}Current version not available...exiting. Is the app installed?${NC}"
  echo
  exit 1
fi

# compare
if [ "$latest_version" = "$running_version" ]; then
  echo -e "${R}No new version available...exiting${NC}"
  echo
  exit
else
  echo -e "${G}New version ${latest_version} available...possible to upgrade${NC}"
fi

#-----------------------------------------------------------------

#
### check if btc-rpc-explorer service is still active (exit if so)
#
if systemctl is-active --quiet "${EXPLORER_SERVICE}"; then
  echo -e "${R}BTC-RPC-Explorer service still running...exiting!${NC}"
  echo
  echo -e "${LB}Stop the service via:${NC}"
  echo " systemctl stop ${EXPLORER_SERVICE} (as root)"
  echo " sudo systemctl stop ${EXPLORER_SERVICE} (as satoshi)"
  echo
  exit
else
  echo -e "${G}BTC-RPC-Explorer service not running${NC}"
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
### update the btc-rpc-explorer application
#
echo
echo -e "${Y}Update the BTC-RPC-Explorer application...${NC}"
echo -e "${LB}This can take several minutes!${NC}"
# update
git config --global --add safe.directory "${EXPLORER_DIR}"
cd "${EXPLORER_DIR}"
git fetch
git checkout "v${latest_version}"
# install/build
cd "${EXPLORER_DIR}"
# update npm (based on warnings)
npm install -g npm@"${NPM_UPD_VER}"
npm install
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### clean up npm caches from build
#
echo
echo -e "${Y}Clean npm caches from build...${NC}"
# clean the npm cache and delete npm cache dir
npm cache clean --force
rm -rf "$(npm get cache)"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permissions of the /home/satoshi/btc-rpc-explorer dir to user satoshi
#
echo
echo -e "${Y}Change permissions of ${EXPLORER_DIR} to user ${USER}...${NC}"
chown -R "${USER}":"${USER}" "${EXPLORER_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Upgrade all done!${NC}"
echo
echo -e "${LB}Start BTC-RPC-Explorer service again via:${NC}"
echo " systemctl start ${EXPLORER_SERVICE} (as root)"
echo " sudo systemctl start ${EXPLORER_SERVICE} (as satoshi)"
echo



