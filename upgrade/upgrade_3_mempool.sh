#!/bin/bash

#
### upgrade mempool (if possible)
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
echo -e "${Y}This script will check for a new Mempool version and upgrade if possible...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Check latest Github version against current running version"
echo "- Exit if no new version is available"
echo "- Exit if Mempool service is still active"
echo "- Request user to confirm to upgrade to the new version (by user interaction)"
echo "- Update the Mempool release"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
### check for new version
#
echo
echo -e "${Y}Check Github version and compare to running version...${NC}"
latest_version=$(curl -sL https://api.github.com/repos/mempool/mempool/releases/latest | grep tag_name | head -1 | cut -d '"' -f4 | cut -c2-)
running_version=$(jq -r ".version" "${MEMPOOL_BACKEND_DIR}"/package.json)
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
### check if mempool service is still active (exit if so)
#
if systemctl is-active --quiet "${MEMPOOL_SERVICE}"; then
  echo -e "${R}Mempool service still running...exiting!${NC}"
  echo
  echo -e "${LB}Stop the service via:${NC}"
  echo " systemctl stop ${MEMPOOL_SERVICE} (as root)"
  echo " sudo systemctl stop ${MEMPOOL_SERVICE} (as satoshi)"
  echo
  exit
else
  echo -e "${G}Mempool service not running${NC}"
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
### install latest rust
#
echo
echo -e "${Y}Install latest rust...${NC}"
# https://rustup.rs/
wget -O /tmp/rustup.sh https://sh.rustup.rs
chmod +x /tmp/rustup.sh
/tmp/rustup.sh -y
rm /tmp/rustup.sh
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### update the mempool application
#
echo
echo -e "${Y}Update the Mempool application...${NC}"
echo -e "${LB}This can take several minutes!${NC}"
# update
git config --global --add safe.directory "${MEMPOOL_DIR}"
cd "${MEMPOOL_DIR}"
git fetch
git reset --hard
git -c advice.detachedHead=false checkout "v${latest_version}"
# build backend
# set config
npm config set registry=https://registry.npmjs.com/
# install/build
cd "${MEMPOOL_DIR}"/rust/gbt
export PATH="$PATH:/root/.cargo/bin/"
cargo update
cd "${MEMPOOL_BACKEND_DIR}"
# update npm (based on warnings)
npm install -g npm@"${NPM_UPD_VER}"
npm install --omit=dev
npm run build
# build frontend
cd "${MEMPOOL_FRONTEND_DIR}"
npm install --omit=dev
npm run build
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### Move the content of the frontend/dist directory into /var/www/html/ directory (web root)
#
echo
echo -e "${Y}Move frontend dist dir into the web root dir...${NC}"
rm -rf "${NGINX_WEBROOT_DIR}"/mempool
mv "${MEMPOOL_FRONTEND_DIR}"/dist/mempool "${NGINX_WEBROOT_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permission of mempool web root dir to www-data
#
echo
echo -e "${Y}Change permission of mempool web dir for www-data...${NC}"
chown -R www-data:www-data "${MEMPOOL_WEBROOT_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permissions of the /home/satoshi/mempool dir to user satoshi
#
echo
echo -e "${Y}Change permissions of ${MEMPOOL_DIR} to user ${USER}...${NC}"
chown -R "${USER}":"${USER}" "${MEMPOOL_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### uninstall rust
#
echo
echo -e "${Y}Uninstall rust...${NC}"
# uninstall rust
/root/.cargo/bin/rustup self uninstall -y
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Upgrade all done!${NC}"
echo
echo -e "${LB}Start Mempool service again via:${NC}"
echo " systemctl start ${MEMPOOL_SERVICE} (as root)"
echo " sudo systemctl start ${MEMPOOL_SERVICE} (as satoshi)"
echo
