#!/bin/bash


#
# config
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
# stop bitcoin service
#
echo
echo -e "${Y}Stop bitcoind service...${NC}"
systemctl stop bitcoind.service
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable bitcoin service
#
echo
echo -e "${Y}Disable bitcoind service...${NC}"
systemctl disable bitcoind.service
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete bitcoin download dir
#
echo
echo -e "${Y}Delete bitcoin download dir...${NC}"
rm -rf "${BITCOIN_DOWNLOAD_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete .bitcoin dir
#
echo
echo -e "${Y}Delete bitcoin base dir (.bitcoin)...${NC}"
rm -rf "${BITCOIN_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete bitcoin service file
#
echo
echo -e "${Y}Delete bitcoin system service sile...${NC}"
rm "${BITCOIN_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete Bitcoin apps from /usr/local/bin
#
echo
echo -e "${Y}Delete Bitcoin apps from /usr/local/bin...${NC}"
rm "/usr/local/bin/bitcoin-cli"
rm "/usr/local/bin/bitcoin-qt"
rm "/usr/local/bin/bitcoin-tx"
rm "/usr/local/bin/bitcoin-util"
rm "/usr/local/bin/bitcoin-wallet"
rm "/usr/local/bin/bitcoind"
rm "/usr/local/bin/test_bitcoin"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Un-installation all done!${NC}"
echo
