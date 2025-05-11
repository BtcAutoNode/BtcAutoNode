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
echo -e "${Y}This script will uninstall all files/folders of the UTXOracle installation...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Stop UTXOracle systemd service (${UTXORACLE_SERVICE})"
echo "- Disable UTXOracle systemd service (${UTXORACLE_SERVICE})"
echo "- Delete UTXOracle systemd service file (${UTXORACLE_SERVICE_FILE})"
echo "- Delete UTXOracle base dir (${UTXORACLE_DIR})"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
# stop utxoracle service
#
echo
echo -e "${Y}Stop UTXOracle service (${UTXORACLE_SERVICE})...${NC}"
systemctl stop "${UTXORACLE_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable utxoracle service
#
echo
echo -e "${Y}Disable UTXOracle service (${UTXORACLE_SERVICE})...${NC}"
systemctl disable "${UTXORACLE_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete utxoracle service file
#
echo
echo -e "${Y}Delete UTXOracle systemd service file (${UTXORACLE_SERVICE_FILE})...${NC}"
rm -f "${UTXORACLE_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete utxoracle base dir
#
echo
echo -e "${Y}Delete UTXOracle base dir (${UTXORACLE_DIR})...${NC}"
rm -rf "${UTXORACLE_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Uninstallation all done!${NC}"
echo
