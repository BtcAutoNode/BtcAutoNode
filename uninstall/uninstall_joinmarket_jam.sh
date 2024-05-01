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
echo -e "${Y}This script will uninstall all files/folders of the JoinMarket / Jam installation...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Stop Jam systemd service (${JAM_SERVICE})"
echo "- Stop JoinMarket API systemd service (${JM_WALLETD_SERVICE})"
echo "- Stop JoinMarket OrderBook watcher systemd service (${JM_OBWATCHER_SERVICE})"
echo "- Disable Jam systemd service (${JAM_SERVICE})"
echo "- Disable JoinMarket API systemd service (${JM_WALLETD_SERVICE})"
echo "- Disable JoinMarket OrderBook watcher systemd service (${JM_OBWATCHER_SERVICE})"
echo "- Delete Jam systemd service file (${JAM_SERVICE_FILE})"
echo "- Delete JoinMarket API systemd service file (${JM_WALLETD_SERVICE_FILE})"
echo "- Delete JoinMarket OrderBook watcher systemd service file (${JM_OBWATCHER_SERVICE_FILE})"
echo "- Uninstall package dependencies via apt-get (${JM_PKGS})"
echo "- Delete JoinMarket base dir (${JM_DIR})"
echo "- Delete JoinMarket data dir (${JM_DATA_DIR})"
echo "- Delete JoinMarket download dir (${JM_DOWNLOAD_DIR})"
echo "- Delete Jam base dir (${JAM_DIR})"
echo "- Delete JAM nginx ssl config (${JAM_NGINX_SSL_CONF})"
echo "- Restart nginx web server"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
# stop jam service
#
echo
echo -e "${Y}Stop Jam service (${JAM_SERVICE})...${NC}"
systemctl stop "${JAM_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# stop jmwalletd service
#
echo
echo -e "${Y}Stop JoinMarket API service (${JM_WALLETD_SERVICE})...${NC}"
systemctl stop "${JM_WALLETD_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# stop obwatcher service
#
echo
echo -e "${Y}Stop JoinMarket OrderBook watcher service (${JM_OBWATCHER_SERVICE})...${NC}"
systemctl stop "${JM_OBWATCHER_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable jam service
#
echo
echo -e "${Y}Disable Jam systemd service (${JAM_SERVICE})...${NC}"
systemctl disable "${JAM_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable jmwalletd service
#
echo
echo -e "${Y}Disable JoinMarket API systemd service (${JM_WALLETD_SERVICE})...${NC}"
systemctl disable "${JM_WALLETD_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable obwatcher service
#
echo
echo -e "${Y}Disable JoinMarket OrderBook watcher systemd service (${JM_OBWATCHER_SERVICE})...${NC}"
systemctl disable "${JM_OBWATCHER_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete jam service file
#
echo
echo -e "${Y}Delete Jam systemd service file (${JAM_SERVICE_FILE})...${NC}"
rm -f "${JAM_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete jmwalletd service
#
echo
echo -e "${Y}Delete JoinMarket API systemd service file (${JM_WALLETD_SERVICE_FILE})...${NC}"
rm -f "${JM_WALLETD_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete obwatcher service
#
echo
echo -e "${Y}Delete JoinMarket OrderBook watcher systemd service file (${JM_OBWATCHER_SERVICE_FILE})...${NC}"
rm -f "${JM_OBWATCHER_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### uninstall dependencies
#
echo
echo -e "${Y}Uninstall dependencies...${NC}"
for i in ${JM_PKGS}; do
  echo -e "${LB}Uninstall package ${i} ...${NC}"
  apt-get -q remove -y "${i}"
  echo -e "${LB}Done.${NC}"
done
apt-get -q autoremove -y
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete joinmarket base dir
#
echo
echo -e "${Y}Delete JoinMarket base dir (${JM_DIR})...${NC}"
rm -rf "${JM_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete joinmarket data dir
#
echo
echo -e "${Y}Delete JoinMarket data dir (${JM_DATA_DIR})...${NC}"
rm -rf "${JM_DATA_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete joinmarket download dir
#
echo
echo -e "${Y}Delete JoinMarket download dir (${JM_DOWNLOAD_DIR})...${NC}"
rm -rf "${JM_DOWNLOAD_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete jam base dir
#
echo
echo -e "${Y}Delete Jam base dir (${JAM_DIR})...${NC}"
rm -rf "${JAM_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# jam nginx config file
#
echo
echo -e "${Y}Delete Jam nginx config (${JAM_NGINX_SSL_CONF})...${NC}"
rm -f "${JAM_NGINX_SSL_CONF}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# restart nginx
#
echo
echo -e "${Y}Restart Nginx...${NC}"
systemctl restart nginx
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Uninstallation all done!${NC}"
echo

