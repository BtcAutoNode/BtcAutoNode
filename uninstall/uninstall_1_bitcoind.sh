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
echo -e "${Y}This script will uninstall all files/folders of the Bitcoin installation...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Stop bitcoind systemd service (${BITCOIN_SERVICE})"
echo "- Disable bitcoind systemd service (${BITCOIN_SERVICE})"
echo "- Delete bitcoind systemd service file (${BITCOIN_SERVICE_FILE})"
echo "- Delete bitcoin download dir (${BITCOIN_DOWNLOAD_DIR})"
echo "- Delete bitcoin base dir (${BITCOIN_DIR})"
echo "- Delete bitcoin app binaries from /usr/local/bin"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
# stop bitcoind service
#
echo
echo -e "${Y}Stop bitcoind service (${BITCOIN_SERVICE})...${NC}"
systemctl stop "${BITCOIN_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable bitcoind service
#
echo
echo -e "${Y}Disable bitcoind service (${BITCOIN_SERVICE})...${NC}"
systemctl disable "${BITCOIN_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete bitcoind service file
#
echo
echo -e "${Y}Delete bitcoind systemd service file (${BITCOIN_SERVICE_FILE})...${NC}"
rm -f "${BITCOIN_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete bitcoin download dir
#
echo
echo -e "${Y}Delete bitcoin download dir (${BITCOIN_DOWNLOAD_DIR})...${NC}"
rm -rf "${BITCOIN_DOWNLOAD_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete .bitcoin base dir
#
echo
echo -e "${Y}Delete bitcoin base dir (${BITCOIN_DIR})...${NC}"
rm -rf "${BITCOIN_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete Bitcoin apps from /usr/local/bin
#
echo
echo -e "${Y}Delete Bitcoin apps from /usr/local/bin...${NC}"
rm -f "/usr/local/bin/bitcoin-cli"
rm -f "/usr/local/bin/bitcoin-qt"
rm -f "/usr/local/bin/bitcoin-tx"
rm -f "/usr/local/bin/bitcoin-util"
rm -f "/usr/local/bin/bitcoin-wallet"
rm -f "/usr/local/bin/bitcoind"
rm -f "/usr/local/bin/test_bitcoin"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Uninstallation all done!${NC}"
echo
