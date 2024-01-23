#!/bin/bash

#
### upgrade bitcoind (if possible)
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
echo -e "${Y}This script will check for a new Bitcoin version and upgrade if possible...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Check latest Github version against current running version"
echo "- Exit if no new version is available"
echo "- Exit if Bitcoin service is still active"
echo "- Request user to confirm to upgrade to the new version (by user interaction)"
echo "- Download new Bitcoin release files"
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
latest_version=$(curl -sL https://github.com/bitcoin/bitcoin/releases/latest | grep "<title>Release" | cut -d ' ' -f 6)
running_version=$(bitcoin-cli --version | grep version | cut -d ' ' -f 6 | cut -c2-5)
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
BITCOIN_VERSION="${latest_version}"
#echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### check if bitcoind service is still active (exit if so)
#
if systemctl is-active --quiet "${BITCOIN_SERVICE}"; then
  echo -e "${R}Bitcoind service still running...exiting!${NC}"
  echo
  echo -e "${LB}Stop the service via:${NC}"
  echo " systemctl stop ${BITCOIN_SERVICE} (as root)"
  echo " sudo systemctl stop ${BITCOIN_SERVICE} (as satoshi)"
  echo
  exit
else
  echo -e "${G}Bitcoind service not running${NC}"
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
### download what is needed for bitcoind
#
echo
echo -e "${Y}Download Bitcoin release files...${NC}"
cd "${BITCOIN_DOWNLOAD_DIR}"
# bitcoind release
wget -O bitcoin-"${BITCOIN_VERSION}"-x86_64-linux-gnu.tar.gz \
        https://bitcoincore.org/bin/bitcoin-core-"${BITCOIN_VERSION}"/bitcoin-"${BITCOIN_VERSION}"-x86_64-linux-gnu.tar.gz
wget -O SHA256SUMS https://bitcoincore.org/bin/bitcoin-core-"${BITCOIN_VERSION}"/SHA256SUMS
wget -O SHA256SUMS.asc https://bitcoincore.org/bin/bitcoin-core-"${BITCOIN_VERSION}"/SHA256SUMS.asc
# rpc-auth python script
wget -O rpcauth.py https://raw.githubusercontent.com/bitcoin/bitcoin/master/share/rpcauth/rpcauth.py
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### verify the release
#
echo
echo -e "${Y}Verify the release files...${NC}"
# checksum
sha256sum --ignore-missing --check --status SHA256SUMS
if [ "$?" -eq 0 ]; then
  echo -e "${G}Verification of release checksum in checksum file: OK${NC}"
else
  echo -e "${R}Verification of release checksum: Not OK${NC}"
  exit
fi
# download the repo with the builder keys
rm -rf guix.sigs
git clone https://github.com/bitcoin-core/guix.sigs
# import into gpg
gpg --import -q guix.sigs/builder-keys/* || true
# verify
gpg --verify SHA256SUMS.asc 
if [ "$?" != 0 ]; then
  echo -e "${R}The signature(s) for the downloaded file are not good signature. Exiting now.${NC}"
  exit 1
else
  echo -e "${G}The signature(s) for the downloaded file are good signature(s).${NC}"
fi
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### installing applications into /usr/local/bin
#
echo
echo -e "${Y}Extract release and install the Bitcoin apps into /usr/local/bin/...${NC}"
cd "${BITCOIN_DOWNLOAD_DIR}"
tar xfz bitcoin-"${BITCOIN_VERSION}"-x86_64-linux-gnu.tar.gz
install -m 0755 -o root -g root -t /usr/local/bin "${BITCOIN_DOWNLOAD_DIR}"/bitcoin-"${BITCOIN_VERSION}"/bin/*
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Upgrade all done!${NC}"
echo
echo -e "${LB}Start Bitcoin service again via:${NC}"
echo " systemctl start ${BITCOIN_SERVICE} (as root)"
echo " sudo systemctl start ${BITCOIN_SERVICE} (as satoshi)"
echo

