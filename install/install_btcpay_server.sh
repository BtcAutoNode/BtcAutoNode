#!/bin/bash

#
### download and install BTCPay Server (Open-Source Bitcoin Payment Processor)
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
### Check if user really wants to install...or exit
#
echo
echo -e "${Y}This script will download and install BTCPay Server...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Upgrade system to newest software (apt-get update / apt-get upgrade)"
echo "- Install MS Dotnet (.NET) Core SDK version ${BTCPAY_DOTNET_VERSION} via script into (${BTCPAY_DOTNET_DIR})"
echo "- Add Postgres repository to apt sources configs (${BTCPAY_LIST_FILE})"
echo "- Install Postgres packages (${BTCPAY_PKGS})"
echo "- Create PostgreSQL admin user/role and databases (nbxplorer / btcpayserver)"
echo "- Clone and build NBXplorer version ${BTCPAY_NBX_VERSION} into ${BTCPAY_NBX_DIR}"
echo "- Create NBXplorer data dir (${BTCPAY_NBX_DATA_DIR})"
echo "- Write NBXplorer config (${BTCPAY_NBX_CONF_FILE})"
echo "- Create NBXplorer systemd service file (${BTCPAY_NBX_SERVICE_FILE})"
echo "- Change permissions of the NMBXplorer dirs for user ${USER}"
echo " ---------------------------------------------------------------------------------"
echo "- Clone and build BTCPay Server version ${BTCPAY_VERSION} into ${BTCPAY_DIR} and adapt run.sh/build.sh files"
echo "- Create BTCPay Server data dir (${BTCPAY_DATA_DIR})"
echo "- Write BTCPay Server config (${BTCPAY_CONF_FILE})"
echo "- Create BTCPay Server systemd service file (${BTCPAY_SERVICE_FILE})"
echo "- Change permissions of the BTCPay Server dirs for user ${USER}"
echo "- Write nginx BTCPay Server reverse proxy ssl config (${BTCPAY_NGINX_SSL_CONF})"
echo "- Check nginx configs and reload nginx web server"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

# clear screen
clear

#-----------------------------------------------------------------

#
### update / upgrade system
#
echo
echo -e "${Y}Updating the system via apt-get...${NC}"
apt-get -q update && apt-get upgrade -y
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### install ms dotnet core sdk via script
#
echo
echo -e "${Y}Install MS Dotnet (.NET) Core SDK via script...${NC}"
cd "${HOME_DIR}"
# download script and make executable
echo -e "${LB}Download script dotnet-install.sh and make it executable${NC}"
wget https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.sh
chmod +x dotnet-install.sh
# install
echo -e "${LB}Install via script${NC}"
./dotnet-install.sh --channel "${BTCPAY_DOTNET_VERSION}" --install-dir "${BTCPAY_DOTNET_DIR}"
# print version
echo -e "${LB}Print dotnet version${NC}"
"${BTCPAY_DOTNET_DIR}"/dotnet --version
# delete install script
echo -e "${LB}Delete install script dotnet-install.sh${NC}"
rm -f dotnet-install.sh
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### add postgres repository to new /etc/apt/sources.list.d/pgdg.list file
#
echo
echo -e "${Y}Add Postgres repository to apt configs${NC}"
echo -e "${LB}Create new repository file (${BTCPAY_LIST_FILE})${NC}"
touch "${BTCPAY_LIST_FILE}"
echo "deb http://apt.postgresql.org/pub/repos/apt/ ${RELEASE_CODE}-pgdg main" >> "${BTCPAY_LIST_FILE}"
echo -e "${LB}Download and add Postgres repository gpg key${NC}"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### refresh apt repositories
#
echo
echo -e "${Y}Updating system via apt with new Postgres repository...${NC}"
apt-get update
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### install postgres packages
#
echo
echo -e "${Y}Installing packages...${NC}"
for i in ${BTCPAY_PKGS}; do
  echo -e "${LB}Installing package ${i} ...${NC}"
  apt-get -q install -y "${i}"
  echo -e "${LB}Done.${NC}"
done
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create postgresql user and databases
#
echo
echo -e "${Y}Create PostgreSQL admin user/role and databases (nbxplorer / btcpayserver)...${NC}"
# create postgres user/role admin with pw admin
echo -e "${LB}Create postgres user/role admin with pw 'admin'${NC}"
sudo -i -u postgres psql -c "CREATE USER admin WITH PASSWORD 'admin' NOSUPERUSER CREATEDB NOCREATEROLE;"
# print postgres user/role
echo -e "${LB}Print Postgres users/roles${NC}"
sudo -i -u postgres psql -c "\du;"
# create database for nbxplorer owned by admin (db nbxplorer)
echo -e "${LB}Create database for nbxplorer owned by admin${NC}"
sudo -i -u postgres psql -c "CREATE DATABASE nbxplorer WITH OWNER=admin;"
# create database for btcpayserver owned by admin (db btcpayserver)
echo -e "${LB}Create database for btcpayserver owned by admin${NC}"
sudo -i -u postgres psql -c "CREATE DATABASE btcpayserver WITH OWNER=admin;"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### Install nbxplorer
#
echo
echo -e "${Y}Clone NBXplorer into ${BTCPAY_NBX_DIR} and build...${NC}"
# clone repo
echo -e "${LB}Clone repository${NC}"
git clone --branch v"${BTCPAY_NBX_VERSION}" https://github.com/dgarage/NBXplorer.git -c advice.detachedHead=false
cd NBXplorer
# change row in run.sh (dotnet --> /home/satoshi/.dotnet/dotnet)
echo -e "${LB}Change row in run.sh/build.sh (replace 'dotnet' --> '${BTCPAY_DOTNET_DIR}/dotnet')${NC}"
sed -i "s|^dotnet|/home/satoshi/.dotnet/dotnet|g" run.sh
# add line to opt out from dotnet telemetry
echo -e "${LB}Add env variable to opt out from dotnet telemetry in run.sh${NC}"
sed -i '3iexport DOTNET_CLI_TELEMETRY_OPTOUT=1' run.sh
# change row in build.sh (dotnet --> /home/satoshi/.dotnet/dotnet)
sed -i "s|^dotnet|/home/satoshi/.dotnet/dotnet|g" build.sh
# add line to opt out from dotnet telemetry
echo -e "${LB}Add env variable to opt out from dotnet telemetry in build.sh${NC}"
sed -i '3iexport DOTNET_CLI_TELEMETRY_OPTOUT=1' build.sh
# build
echo -e "${LB}Build...${NC}"
./build.sh
# print build version
echo -e "${LB}Print NBXplorer build version${NC}"
head -n 6 /home/satoshi/NBXplorer/NBXplorer/NBXplorer.csproj | grep Version
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create nbxplorer data dir
#
echo
echo -e "${Y}Create NBXplorer data dir (${BTCPAY_NBX_DATA_DIR})...${NC}"
mkdir -p "${BTCPAY_NBX_DATA_DIR}"
mkdir -p "${BTCPAY_NBX_DATA_DIR}"/Main
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create nbxplorer config
#
echo
echo -e "${Y}Write NBXplorer config (${BTCPAY_NBX_CONF_FILE})...${NC}"
cat > "${BTCPAY_NBX_CONF_FILE}"<< EOF
# nbxplorer configuration
# /home/satoshi/.nbxplorer/Main/settings.config

# Bitcoind connection
btc.rpc.cookiefile=${BITCOIN_DIR}/.cookie

# Database
postgres=User ID=admin;Password=admin;Host=localhost;Port=5432;Database=nbxplorer;
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create systemd service file for nbxplorer
#
echo
echo -e "${Y}Create systemd service file for NBXplorer ${BTCPAY_NBX_SERVICE_FILE}...${NC}"
cat > "${BTCPAY_NBX_SERVICE_FILE}"<< EOF
#
# systemd unit for NBXplorer
# /etc/systemd/system/nbxplorer.service
#

[Unit]
Description=NBXplorer
Wants=bitcoind.service
After=bitcoind.service

[Service]
WorkingDirectory=${BTCPAY_NBX_DIR}
ExecStart=${BTCPAY_NBX_DIR}/run.sh

User=${USER}
Group=${USER}

# Process management
####################
Type=simple
TimeoutSec=120

# Hardening Measures
####################
PrivateTmp=true
ProtectSystem=full
NoNewPrivileges=true
PrivateDevices=true

[Install]
WantedBy=multi-user.target

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permissions of the joinmarket dirs for user satoshi
#
echo
echo -e "${Y}Change permissions of the NMBXplorer dirs for user ${USER}...${NC}"
chown -R "${USER}":"${USER}" "${BTCPAY_NBX_DIR}"
chown -R "${USER}":"${USER}" "${BTCPAY_NBX_DATA_DIR}"
chown -R "${USER}":"${USER}" "${BTCPAY_DOTNET_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------
# BTCPay Server installation
#-----------------------------------------------------------------

#
### Clone btcpayserver
#
echo
echo -e "${Y}Clone BTCPay Server into ${BTCPAY_DIR} and build...${NC}"
cd "${HOME_DIR}"
# clone repo
echo -e "${LB}Clone repository${NC}"
git clone --branch v"${BTCPAY_VERSION}" https://github.com/btcpayserver/btcpayserver -c advice.detachedHead=false
cd btcpayserver
echo -e "${LB}Change row in run.sh/build.sh (replace 'dotnet' --> '/home/satoshi/.dotnet/dotnet')${NC}"
# change row in run.sh (dotnet --> /home/satoshi/.dotnet/dotnet)
sed -i "s|^dotnet|/home/satoshi/.dotnet/dotnet|g" run.sh
# add line to opt out from dotnet telemetry
echo -e "${LB}Add env variable to opt out from dotnet telemetry in run.sh${NC}"
sed -i '3iexport DOTNET_CLI_TELEMETRY_OPTOUT=1' run.sh
# change row in build.sh (dotnet --> /home/satoshi/.dotnet/dotnet)
sed -i "s|^dotnet|/home/satoshi/.dotnet/dotnet|g" build.sh
# add line to opt out from dotnet telemetry
echo -e "${LB}Add env variable to opt out from dotnet telemetry in build.sh${NC}"
sed -i '3iexport DOTNET_CLI_TELEMETRY_OPTOUT=1' build.sh
# build
echo -e "${LB}Build...${NC}"
./build.sh
# print build version
echo -e "${LB}Print BTCPay Server build version${NC}"
head -n 3 /home/satoshi/btcpayserver/Build/Version.csproj | grep Version
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create btcpayserver data dir
#
echo
echo -e "${Y}Create BTCPay Server data dir (${BTCPAY_DATA_DIR})...${NC}"
mkdir -p "${BTCPAY_DATA_DIR}"
mkdir -p "${BTCPAY_DATA_DIR}/Main"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create btcpayserver config
#
echo
echo -e "${Y}Write BTCPay Server config (${BTCPAY_CONF_FILE})...${NC}"
cat > "${BTCPAY_CONF_FILE}"<< EOF
# btcpayserver configuration
# /home/satoshi/.btcpayserver/Main/settings.config
### Global settings ###
network=mainnet

### Server settings ###
port=23000
bind=127.0.0.1
#httpscertificatefilepath=devtest.pfx
#httpscertificatefilepassword=toto

### Database ###
postgres=User ID=admin;Password=admin;Host=localhost;Port=5432;Database=btcpay;

### NBXplorer settings ###
BTC.explorer.url=http://127.0.0.1:24444/
BTC.explorer.cookiefile=/home/satoshi/.nbxplorer/Main/.cookie
BTC.blockexplorerlink=${LOCAL_IP}:${MEMPOOL_SSL_PORT}/tx/{0}
#BTC.lightning=/root/.lightning/lightning-rpc
#BTC.lightning=https://apitoken:API_TOKEN_SECRET@charge.example.com/
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------


#
### create systemd service file for btcpayserver
#
echo
echo -e "${Y}Create systemd service file for BTCPay Server ${BTCPAY_SERVICE_FILE}...${NC}"
cat > "${BTCPAY_SERVICE_FILE}"<< EOF
#
# systemd unit for BTCpay server
# /etc/systemd/system/btcpay.service
#

[Unit]
Description=BTCPay Server
Wants=nbxplorer.service
After=nbxplorer.service

[Service]
WorkingDirectory=${BTCPAY_DIR}
ExecStart=${BTCPAY_DIR}/run.sh

User=${USER}
Group=${USER}

# Process management
####################
Type=simple
TimeoutSec=120

[Install]
WantedBy=multi-user.target

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permissions of the btcpayserver dir and data dirs for user satoshi
#
echo
echo -e "${Y}Change permissions of the BTCPay Server dirs for user ${USER}...${NC}"
chown -R "${USER}":"${USER}" "${BTCPAY_DIR}"
chown -R "${USER}":"${USER}" "${BTCPAY_DATA_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### nginx btcpayserver reverse proxy ssl config
#
echo
echo -e "${Y}Write nginx BTCPay Server reverse proxy ssl config (${BTCPAY_NGINX_SSL_CONF})...${NC}"
cat > "${BTCPAY_NGINX_SSL_CONF}"<< EOF

upstream btcpay {
  server 127.0.0.1:23000;
}
server {
  listen 4030 ssl;
  listen [::]:4030 ssl;
  proxy_pass btcpay;
}

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### check nginx config
#
echo
echo -e "${Y}Checking nginx configs...${NC}"
if nginx -t; then
  echo -e "${G}Nginx configs: OK${NC}"
else
  echo -e "${R}Nginx configs: Not OK${NC}"
  exit
fi
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### reload nginx webserver
#
echo
echo -e "${Y}Restart Nginx web server...${NC}"
systemctl reload nginx
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### delete installation/build dirs in /root dir
#
echo
echo -e "${Y}Delete installation/build dirs in /root dir...${NC}"
rm -rf /root/.dotnet
rm -rf /root/.nuget
rm -rf /root/.local/share/NuGet
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Installation all done!${NC}"
echo
echo -e "${LB}Systemd Service (as root or with sudo as user):${NC}"
echo -e " systemctl enable ${BTCPAY_NBX_SERVICE} + - enable service after boot\n" \
        "systemctl start ${BTCPAY_NBX_SERVICE} + - start NBXplorer service\n" \
        "systemctl stop ${BTCPAY_NBX_SERVICE} + - stop NBXplorer service\n" \
        "systemctl status ${BTCPAY_NBX_SERVICE} + - show service status\n" \
        "+\n" \
        "systemctl enable ${BTCPAY_SERVICE} + - enable service after boot\n" \
        "systemctl start ${BTCPAY_SERVICE} + - start BTCPay Server service\n" \
        "systemctl stop ${BTCPAY_SERVICE}  + - stop BTCPay Server service\n" \
        "systemctl status ${BTCPAY_SERVICE} + - show service status" | column -t -s "+"
echo
echo -e "${LB}View Log:${NC}"
echo " journalctl -fu ${BTCPAY_NBX_SERVICE}"
echo " journalctl -fu ${BTCPAY_SERVICE}"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${BTCPAY_NBX_DIR} + - NBXplorer base directory\n" \
        "${BTCPAY_NBX_DATA_DIR} + - NBXplorer data/working dir\n" \
        "+\n" \
        "${BTCPAY_NBX_CONF_FILE} + - NBXplorer config file\n" \
        "+\n" \
        "${BTCPAY_NBX_SERVICE_FILE} + - NBXplorer systemd service file\n" \
        "+\n" \
        "${BTCPAY_DIR} + - BTCPay Server base dir\n" \
        "${BTCPAY_DATA_DIR} + - BTCPay Server data/working dir\n" \
        "+\n" \
        "${BTCPAY_CONF_FILE} + - BTCPay Server config file\n" \
        "+\n" \
        "${BTCPAY_SERVICE_FILE} + - JBTCPay Server systemd service file\n" \
        "+\n" \
        "${BTCPAY_NGINX_SSL_CONF} + - BTCPay Server nginx ssl config\n" | column -t -s "+"
echo
echo
echo -e "0) ${LB}Bitcoind must be running with blockchain synced${NC}"
echo
echo -e "1) ${LB}Start the NBXplorer service:${NC} systemctl start ${BTCPAY_NBX_SERVICE}"
echo
echo -e "2) ${LB}Start the BTCPay Server service:${NC} systemctl start ${BTCPAY_SERVICE}"
echo
echo -e "3) ${LB}Open the BTCPay Server page in your browser via the following URL: ${NC}"
echo " https://${LOCAL_IP}:${BTCPAY_SSL_PORT}"
echo

