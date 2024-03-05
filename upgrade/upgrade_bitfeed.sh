#!/bin/bash

#
### upgrade bitfeed (if possible)
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
echo -e "${Y}This script will check for a new Bitfeed version and upgrade if possible...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Check latest Github version against current running version"
echo "- Exit if no new version is available"
echo "- Exit if Bitfeed service is still active"
echo "- Request user to confirm to upgrade to the new version (by user interaction)"
echo "- Update the Bitfeed release"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
### check for new version
#
echo
echo -e "${Y}Check Github version and compare to running version...${NC}"
latest_version=$(curl -sL https://github.com/bitfeed-project/bitfeed/releases/latest | grep "<title>Release" | cut -d ' ' -f 5 | cut -c2-)
running_version=$(cat "${BITFEED_FRONTEND_DIR}"/package.json | jq -r ".version")
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
BITFEED_VERSION="${latest_version}"
#echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### check if bitfeed service is still active (exit if so)
#
if systemctl is-active --quiet "${BITFEED_SERVICE}"; then
  echo -e "${R}Bitfeed service still running...exiting!${NC}"
  echo
  echo -e "${LB}Stop the service via:${NC}"
  echo " systemctl stop ${BITFEED_SERVICE} (as root)"
  echo " sudo systemctl stop ${BITFEED_SERVICE} (as satoshi)"
  echo
  exit
else
  echo -e "${G}Bitfeed service not running${NC}"
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
### update the bitfeed application
#
echo
echo -e "${Y}Update the Bitfeed application...${NC}"
echo -e "${LB}This can take several minutes!${NC}"
# update
git config --global --add safe.directory "${BITFEED_DIR}"
cd "${BITFEED_DIR}"
git fetch
git checkout "v${latest_version}"
# build backend
cd "${BITFEED_BACKEND_DIR}"
mix local.rebar --force
mix local.hex --force
mix do deps.get
mix do deps.compile
mix release
# build frontend
cd "${BITFEED_FRONTEND_DIR}"
npm install -g npm@"${NPM_UPD_VER}"
npm install
npm run build
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### clean up mix cache dirs from build
#
echo
echo -e "${Y}Clean mix caches from build...${NC}"
rm -rf /root/.mix
rm -rf /root/.hex
rm -rf /root/.cache/rebar3
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
### Move the content of the client/public/build directory into /var/www/html/ directory (web root)
#
echo
echo -e "${Y}Move frontend dist dir into the web root dir...${NC}"
rm -rf "${BITFEED_WEBROOT_DIR}"
mv "${BITFEED_FRONTEND_DIR}"/public/build "${BITFEED_WEBROOT_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permission of bitfeed web root dir to www-data
#
echo
echo -e "${Y}Change permission of Bitfeed web dir for www-data...${NC}"
chown -R www-data:www-data "${BITFEED_WEBROOT_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permissions of the /home/satoshi/bitfeed dir to user satoshi
#
echo
echo -e "${Y}Change permissions of ${BITFEED_DIR} to user ${USER}...${NC}"
chown -R "${USER}":"${USER}" "${BITFEED_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Upgrade all done!${NC}"
echo
echo -e "${LB}Start Bitfeed service again via:${NC}"
echo " systemctl start ${BITFEED_SERVICE} (as root)"
echo " sudo systemctl start ${BITFEED_SERVICE} (as satoshi)"
echo


