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
echo -e "${Y}This script will uninstall all files/folders of the BTCPay Server installation...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Stop BTCPay Server systemd service (${BTCPAY_SERVICE})"
echo "- Stop NBXplorer systemd service (${BTCPAY_NBX_SERVICE})"
echo "- Disable BTCPay Server systemd service (${BTCPAY_SERVICE})"
echo "- Disable NBXplorer systemd service (${BTCPAY_NBX_SERVICE})"
echo "- Delete BTCPay Server systemd service file (${BTCPAY_SERVICE_FILE})"
echo "- Delete NBXplorer systemd service file (${BTCPAY_NBX_SERVICE_FILE})"
echo "- Delete MS Dotnet (.NET Core SDK) dir (${BTCPAY_DOTNET_DIR})"
echo "- Delete BTCPay Server base dir (${BTCPAY_DIR})"
echo "- Delete BTCPay Server data dir (${BTCPAY_DATA_DIR})"
echo "- Delete NBXplorer base dir (${BTCPAY_NBX_DIR})"
echo "- Delete NBXplorer data dir (${BTCPAY_NBX_DATA_DIR})"
echo "- Delete BTCPay Server nginx ssl config (${BTCPAY_NGINX_SSL_CONF})"
echo "- Restart nginx web server"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
# stop btcpayserver service
#
echo
echo -e "${Y}Stop BTCPay Server service (${BTCPAY_SERVICE})...${NC}"
systemctl stop "${BTCPAY_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# stop nbxplorer service
#
echo
echo -e "${Y}Stop NBXplorer service (${BTCPAY_NBX_SERVICE})...${NC}"
systemctl stop "${BTCPAY_NBX_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable btcpayserver service
#
echo
echo -e "${Y}Disable BTCPay Server systemd service (${BTCPAY_SERVICE})...${NC}"
systemctl disable "${BTCPAY_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable nbxplorer service
#
echo
echo -e "${Y}Disable NBXplorer systemd service (${BTCPAY_NBX_SERVICE})...${NC}"
systemctl disable "${BTCPAY_NBX_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete btcpayserver service file
#
echo
echo -e "${Y}Delete BTCPay Server systemd service file (${BTCPAY_SERVICE_FILE})...${NC}"
rm -f "${BTCPAY_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete nbxplorer service file
#
echo
echo -e "${Y}Delete NBXplorer systemd service file (${BTCPAY_NBX_SERVICE_FILE})...${NC}"
rm -f "${BTCPAY_NBX_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### uninstall postgres
#
echo
echo -e "${Y}Uninstall Postgres...${NC}"
# delete dirs
echo -e "${LB}Delete directories...${NC}"
rm -rf /var/lib/postgresql/
rm -rf /var/log/postgresql/
rm -rf /etc/postgresql/
# remove packages
echo -e "${LB}Remove packages...${NC}"
apt-get --purge remove postgresql* -y
apt-get -q autoremove -y
# delete postgres apt sources list file
echo -e "${LB}Delete postgres apt sources list file (${BTCPAY_LIST_FILE})...${NC}"
rm -f "${BTCPAY_LIST_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete dotnet dir
#
echo
echo -e "${Y}Delete MS Dotnet dir (${BTCPAY_DOTNET_DIR})...${NC}"
rm -rf "${BTCPAY_DOTNET_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete btcpayserver base dir
#
echo
echo -e "${Y}Delete BTCPay Server base dir (${BTCPAY_DIR})...${NC}"
rm -rf "${BTCPAY_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete btcpayserver data dir
#
echo
echo -e "${Y}Delete BTCPay Server data dir (${BTCPAY_DATA_DIR})...${NC}"
rm -rf "${BTCPAY_DATA_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete nbxplorer base dir
#
echo
echo -e "${Y}Delete NBXplorer base dir (${BTCPAY_NBX_DIR})...${NC}"
rm -rf "${BTCPAY_NBX_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete nbxplorer data dir
#
echo
echo -e "${Y}Delete NBXplorer base dir (${BTCPAY_NBX_DATA_DIR})...${NC}"
rm -rf "${BTCPAY_NBX_DATA_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete /home/satoshi/.aspnet dir
#
echo
echo -e "${Y}Delete .aspnet dir (${HOME_DIR}/.aspnet)...${NC}"
rm -rf "${HOME_DIR}"/.aspnet
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# btcpayserver nginx config file
#
echo
echo -e "${Y}Delete BTCPAY Server nginx ssl config (${BTCPAY_NGINX_SSL_CONF})...${NC}"
rm -f "${BTCPAY_NGINX_SSL_CONF}"
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

