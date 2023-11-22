#!/bin/bash

#
### upgrade lnd (if possible)
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
echo -e "${Y}This script will check for a new Lnd version and upgrade if possible...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Check latest Github version against current running version"
echo "- Exit if no new version is available"
echo "- Exit if Lnd service is still active"
echo "- Request user to confirm to upgrade to the new version (by user interaction)"
echo "- Download new Lnd release files"
echo "- Verify, extract and install the release"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
### check for new version
#
echo
echo -e "${Y}Check Github version and compare to running version...${NC}"
latest_version=$(curl -sL https://github.com/lightningnetwork/lnd/releases/latest | grep "<title>Release" | cut -d ' ' -f 5 | cut -c2-)
running_version=$(lncli --version | cut -d ' ' -f 3)
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
LND_VERSION="${latest_version}"
#echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### check if lnd service is still active (exit if so)
#
if systemctl is-active --quiet "${LND_SERVICE}"; then
  echo -e "${R}Lnd service still running...exiting!${NC}"
  echo
  echo -e "${LB}Stop the service via:${NC}"
  echo " systemctl stop ${LND_SERVICE} (as root)"
  echo " sudo systemctl stop ${LND_SERVICE} (as satoshi)"
  echo
  exit
else
  echo -e "${G}Lnd service not running${NC}"
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
### download what is needed for Lnd
#
echo
echo -e "${Y}Download Lnd release files...${NC}"
cd "${LND_DOWNLOAD_DIR}"
# lnd release
wget -O lnd-linux-amd64-v"${LND_VERSION}".tar.gz \
        https://github.com/lightningnetwork/lnd/releases/download/v"${LND_VERSION}"/lnd-linux-amd64-v"${LND_VERSION}".tar.gz
wget -O manifest-roasbeef-v"${LND_VERSION}".sig \
        https://github.com/lightningnetwork/lnd/releases/download/v"${LND_VERSION}"/manifest-roasbeef-v"${LND_VERSION}".sig
wget -O manifest-v${LND_VERSION}.txt \
        https://github.com/lightningnetwork/lnd/releases/download/v${LND_VERSION}/manifest-v${LND_VERSION}.txt
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### verify the release
#
echo
echo -e "${Y}Verify the release files...${NC}"
# checksum
sha256sum --ignore-missing --check manifest-v"${LND_VERSION}".txt
if [ "$?" -eq 0 ]; then
  echo -e "${G}Verification of release checksum in checksum file: OK${NC}"
else
  echo -e "${R}Verification of release checksum: Not OK${NC}"
  exit
fi
# download gpg key
wget -O roasbeef.asc https://raw.githubusercontent.com/lightningnetwork/lnd/master/scripts/keys/roasbeef.asc
# import into gpg
gpg --import -q roasbeef.asc || true
# verify
gpg --verify manifest-roasbeef-v"${LND_VERSION}".sig manifest-v"${LND_VERSION}".txt 2>&1 >/dev/null | grep 'Good signature'
if [ "$?" != 0 ]; then
  echo -e "${R}The signature(s) for the downloaded file are not good signature. Exiting now.${NC}"
  exit 1
else
  echo -e "${G}The signature(s) for the downloaded file are good signature(s).${NC}"
fi
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### installing
#
echo
echo -e "${Y}Extract release and install the lnd apps into /usr/local/bin/...${NC}"
cd "${LND_DOWNLOAD_DIR}"
# extract
tar xvfz lnd-linux-amd64-v"${LND_VERSION}".tar.gz
cd lnd-linux-amd64-v"${LND_VERSION}"
# install to /usr/local/bin
install -m 0755 -o root -g root -t /usr/local/bin "${LND_DOWNLOAD_DIR}"/lnd-linux-amd64-v"${LND_VERSION}"/*
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Upgrade all done!${NC}"
echo
echo -e "${LB}Start Lnd service again via:${NC}"
echo " systemctl start ${LND_SERVICE} (as root)"
echo " sudo systemctl start ${LND_SERVICE} (as satoshi)"
echo

