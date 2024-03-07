#!/bin/bash

#
### upgrade fulcrum (if possible)
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
echo -e "${Y}This script will check for a new Fulcrum version and upgrade if possible...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Check latest Github version against current running version"
echo "- Exit if no new version is available"
echo "- Exit if Fulcrum service is still active"
echo "- Request user to confirm to upgrade to the new version (by user interaction)"
echo "- Download new Fulcrum release files"
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
latest_version=$(curl -sL https://github.com/cculianu/Fulcrum/releases/latest | grep "<title>Release" | cut -d ' ' -f 5)
running_version=$("${FULCRUM_DIR}"/Fulcrum --version | grep Release | cut -d ' ' -f 2)
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

# replace so existing commands can be used
FULCRUM_VERSION="${latest_version}"

#-----------------------------------------------------------------

#
### check if fulcrum service is still active (exit if so)
#
if systemctl is-active --quiet "${FULCRUM_SERVICE}"; then
  echo -e "${R}Fulcrum service still running...exiting!${NC}"
  echo
  echo -e "${LB}Stop the service via:${NC}"
  echo " systemctl stop ${FULCRUM_SERVICE} (as root)"
  echo " sudo systemctl stop ${FULCRUM_SERVICE} (as satoshi)"
  echo
  exit
else
  echo -e "${G}Fulcrum service not running${NC}"
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
### download what is needed for Fulcrum
#
echo
echo -e "${Y}Download Fulcrum release files...${NC}"
cd "${FULCRUM_DOWNLOAD_DIR}"
# bitcoind release
wget -O Fulcrum-"${FULCRUM_VERSION}"-x86_64-linux.tar.gz \
        https://github.com/cculianu/Fulcrum/releases/download/v"${FULCRUM_VERSION}"/Fulcrum-"${FULCRUM_VERSION}"-x86_64-linux.tar.gz
wget -O Fulcrum-"${FULCRUM_VERSION}"-shasums.txt.asc \
        https://github.com/cculianu/Fulcrum/releases/download/v"${FULCRUM_VERSION}"/Fulcrum-"${FULCRUM_VERSION}"-shasums.txt.asc
wget -O Fulcrum-"${FULCRUM_VERSION}"-shasums.txt \
        https://github.com/cculianu/Fulcrum/releases/download/v"${FULCRUM_VERSION}"/Fulcrum-"${FULCRUM_VERSION}"-shasums.txt
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### verify the release
#
echo
echo -e "${Y}Verify the release files...${NC}"
# checksum
##sha256sum --ignore-missing --check Fulcrum-"${FULCRUM_VERSION}"-sha256sums.txt
cat Fulcrum-"${FULCRUM_VERSION}"-shasums.txt | grep Fulcrum-"${FULCRUM_VERSION}"-x86_64-linux.tar.gz | shasum --ignore-missing --check
if [ "$?" -eq 0 ]; then
  echo -e "${G}Verification of release checksum in checksum file: OK${NC}"
else
  echo -e "${R}Verification of release checksum: Not OK${NC}"
  exit
fi
# download gpg key
wget -O calinkey.txt https://raw.githubusercontent.com/Electron-Cash/keys-n-hashes/master/pubkeys/calinkey.txt
# import into gpg
gpg --import -q calinkey.txt || true
# verify
gpg --verify Fulcrum-"${FULCRUM_VERSION}"-shasums.txt.asc
if [ "$?" != 0 ]; then
  echo -e "${R}The signature(s) for the downloaded file are not good signature. Exiting now.${NC}"
  exit 1
else
  echo -e "${G}The signature(s) for the downloaded file are good signature(s).${NC}"
fi
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### extract release files
#
echo
echo -e "${Y}Extract release...${NC}"
cd "${FULCRUM_DOWNLOAD_DIR}"
# extract
tar xvfz Fulcrum-"${FULCRUM_VERSION}"-x86_64-linux.tar.gz
cd Fulcrum-"${FULCRUM_VERSION}"-x86_64-linux
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### copy content into Fulcrum dir
#
echo
echo -e "${Y}Copy content of extracted release folder into user's Fulcrum dir...${NC}"
# copy content of extracted Fulcrum dir into the user's Fulcrum dir
cp -r "${FULCRUM_DOWNLOAD_DIR}"/Fulcrum-"${FULCRUM_VERSION}"-x86_64-linux/* "${FULCRUM_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Upgrade all done!${NC}"
echo
echo -e "${LB}Start Fulcrum service again via:${NC}"
echo " systemctl start ${FULCRUM_SERVICE} (as root)"
echo " sudo systemctl start ${FULCRUM_SERVICE} (as satoshi)"
echo

