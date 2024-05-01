#!/bin/bash

#
### download and install JoinMarket (tool to create CoinJoin transactions) + Jam (WebUI)
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
echo -e "${Y}This script will download and install JoinMarket + Jam WebUI...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Upgrade system to newest software (apt-get update / apt-get upgrade)"
echo "- Install missing dependencies via apt (${JM_PKGS})"
echo "- Create JoinMarket download dir in users download dir (${JM_DOWNLOAD_DIR})"
echo "- Download JoinMarket release files, version ${JM_VERSION}"
echo "- Verify and extract the release"
echo "- Create JoinMarket base and data dir (joinmarket / .joinmarket) in ${HOME_DIR}"
echo "- Copy content of extracted release folder into Joinmarket dir (${JM_DIR})"
echo "- Install Joinmarket via install.sh script"
echo "- Activate virtual env and run wallet-tool.py to create the config in ${JM_DATA_DIR}"
echo "- Edit config file and replace/set values (${JM_CONF_FILE})"
echo "- Change permissions of the JoinMarket dirs for user ${USER}"
echo " ---------------------------------------------------------------------------------"
echo "- Edit configuration file and replace/set values (now for JAM) (${JM_CONF_FILE})"
echo "- Generate ssl certificate in JoinMarket data dir (${JM_DATA_DIR}/ssl)"
echo "- Clone the Jam git repository into ${JAM_DIR}"
echo "- Verify the Jam release source code"
echo "- Build the JAM application"
echo "- Write Jam config file ${JAM_CONF_FILE} and overwrite default app port"
echo "- Change permissions of the Jam dir ${JAM_DIR} for user ${USER}"
echo "- Create JoinMarket API systemd service file (${JM_WALLETD_SERVICE})"
echo "- Create JoinMarket OrderBook watcher systemd service file (${JM_OBWATCHER_SERVICE})"
echo "- Create Jam WebUI systemd service file (${JAM_SERVICE})"
echo "- Create nginx ssl config, check nginx and reload nginx web server configs"
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
### install dependencies
#
echo
echo -e "${Y}Installing dependencies...${NC}"
for i in ${JM_PKGS}; do
  echo -e "${LB}Installing package ${i} ...${NC}"
  apt-get -q install -y "${i}"
  echo -e "${LB}Done.${NC}"
done
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create joinmarket download dir
#
echo
echo -e "${Y}Create downloads directory for JoinMarket for user ${USER}...${NC}"
mkdir -p "${JM_DOWNLOAD_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### download what is needed for Joinmarket
#
echo
echo -e "${Y}Download JoinMarket release files...${NC}"
cd "${JM_DOWNLOAD_DIR}"
# joinmarket release
wget -O joinmarket-clientserver-${JM_VERSION}.tar.gz https://github.com/JoinMarket-Org/joinmarket-clientserver/archive/v${JM_VERSION}.tar.gz
wget https://github.com/JoinMarket-Org/joinmarket-clientserver/releases/download/v${JM_VERSION}/joinmarket-clientserver-${JM_VERSION}.tar.gz.asc
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### verify the release
#
echo
echo -e "${Y}Verify the release files...${NC}"
## checksum
#if grep Fulcrum-"${FULCRUM_VERSION}"-x86_64-linux.tar.gz Fulcrum-"${FULCRUM_VERSION}"-shasums.txt | sha256sum --ignore-missing --check; then
#  echo -e "${G}Verification of release checksum in checksum file: OK${NC}"
#else
#  echo -e "${R}Verification of release checksum: Not OK${NC}"
#  exit
#fi
# download gpg key
wget -O AdamGibson.asc https://raw.githubusercontent.com/JoinMarket-Org/joinmarket-clientserver/master/pubkeys/AdamGibson.asc
wget -O KristapsKaupe.asc https://raw.githubusercontent.com/JoinMarket-Org/joinmarket-clientserver/master/pubkeys/KristapsKaupe.asc
# import into gpg
gpg --import -q AdamGibson.asc || true
gpg --import -q KristapsKaupe.asc || true
# verify
if ! gpg --verify joinmarket-clientserver-${JM_VERSION}.tar.gz.asc; then
  echo -e "${R}The signature(s) for the downloaded file are not good signature. Exiting now.${NC}"
  exit 1
else
  echo -e "${G}The signature(s) for the downloaded file are good signature(s).${NC}"
fi
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### extract the release
#
echo
echo -e "${Y}Extract release...${NC}"
cd "${JM_DOWNLOAD_DIR}"
# extract
tar xvfz joinmarket-clientserver-"${JM_VERSION}".tar.gz
cd joinmarket-clientserver-"${JM_VERSION}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create joinmarket base dir and data dir
#
echo
echo -e "${Y}Create JoinMarket base and data dir (joinmarket / .joinmarket) in ${HOME_DIR}...${NC}"
mkdir -p "${JM_DIR}"
mkdir -p "${JM_DATA_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### copy content into joinmarket dir
#
echo
echo -e "${Y}Copy content of extracted release folder into user's Joinmarket dir...${NC}"
cp -r "${JM_DOWNLOAD_DIR}"/joinmarket-clientserver-${JM_VERSION}/* "${JM_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### install via install.sh script
#
echo
echo -e "${Y}Install Joinmarket via install.sh script...${NC}"
cd "${JM_DIR}"
./install.sh --without-qt --disable-secp-check --disable-os-deps-check
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create jmenv activation script
#
echo
echo -e "${Y}Create jmenv (virtual environment) activation script...${NC}"
cat > "${JM_DIR}/activate.sh"<< EOF
#!/usr/bin/env bash
cd ${JM_DIR} && \
source jmvenv/bin/activate && \
cd scripts
EOF
# make script executable
chmod +x "${JM_DIR}/activate.sh"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### activate jmvenv and run wallet-tool.py to create the config file/dir
#
echo
echo -e "${Y}Activate jmvenv and run wallet-tool.py to create the config file/dir...${NC}"
cd "${JM_DIR}"
. activate.sh && ./wallet-tool.py --datadir="${JM_DATA_DIR}" || true
deactivate
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### edit config file and replace/set values
#
echo
echo -e "${Y}Edit configuration file and replace/set values...${NC}"
# rpc port
sed -i "s/rpc_port =/rpc_port = 8332/g" "$JM_CONF_FILE"
# comment out rpcuser
sed -i "s/rpc_user/#rpc_user/g" "$JM_CONF_FILE"
# comment out rpcpassword
sed -i "s/rpc_password/#rpc_password/g" "$JM_CONF_FILE"
# uncomment rpc_cookie_file (using other seperator |))
sed -i "s|#rpc_cookie_file =|rpc_cookie_file = ${BITCOIN_DIR}/.cookie|g" "$JM_CONF_FILE"
# rpc_wallet_file (watch-only wallet needed for addresses in rpc calls))
sed -i "s/rpc_wallet_file =/rpc_wallet_file = jm_wallet/g" "$JM_CONF_FILE"
# onion serving port (to not conflict with lnd)
sed -i "s/onion_serving_port = 8080/onion_serving_port = 8085/g" "$JM_CONF_FILE"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permissions of the joinmarket dirs for user satoshi
#
echo
echo -e "${Y}Change permissions of the JoinMarket dirs for user ${USER}...${NC}"
chown -R "${USER}":"${USER}" "${JM_DOWNLOAD_DIR}"
chown -R "${USER}":"${USER}" "${JM_DIR}"
chown -R "${USER}":"${USER}" "${JM_DATA_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------
# Jam installation
#-----------------------------------------------------------------

#
### edit config file and replace/set values (now for JAM)
#
echo
echo -e "${Y}Edit configuration file and replace/set values (now for JAM)...${NC}"
# no-daemon (does only work with 0)
sed -i "s/no_daemon = 1/no_daemon = 0/g" "$JM_CONF_FILE"
# use ssl
sed -i "s/use_ssl = false/use_ssl = true/g" "$JM_CONF_FILE"
# directory nodes (replace with nodes working at the time of creating this script)
sed -i '/^directory_nodes =/c\directory_nodes = odpwaf67rs5226uabcamvypg3y4bngzmfk7255flcdodesqhsvkptaid.onion:5222,ylegp63psfqh3zk2huckf2xth6dxvh2z364ykjfmvsoze6tkfjceq7qd.onion:5222' "$JM_CONF_FILE"
# max_cj_fee_abs
sed -i "s/#max_cj_fee_abs = x/max_cj_fee_abs = 600/g" "$JM_CONF_FILE"
# max_cj_fee_rel
sed -i "s/#max_cj_fee_rel = x/max_cj_fee_rel = 0.00003/g" "$JM_CONF_FILE"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### generate self-signed certificate in joinmarket’s data directory (.joinmarket)
#
echo
echo -e "${Y}Generate ssl certificate in JoinMarket’s data directory (.joinmarket)...${NC}"
cd "${JM_DATA_DIR}"
mkdir -p ssl/ && cd "$_"
openssl req -newkey rsa:4096 -new -nodes -x509 -days 3650 -keyout key.pem -out cert.pem -subj "/C=/ST=/L=/O=/OU=/CN=localhost"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### cd into homedir and download jam git repository into ${HOME_DIR}
#
echo
echo -e "${Y}Cd into ${HOME_DIR} and clone the Jam git repository...${NC}"
cd "${HOME_DIR}"
# delete dir if exist
rm -rf "${JAM_DIR}"
git clone https://github.com/joinmarket-webui/jam.git -c advice.detachedHead=false --branch v${JAM_VERSION} --depth=1
cd "${JAM_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### verify the source code
#
echo
echo -e "${Y}Verify the release source code...${NC}"
# download gpg key
wget -O PGP.txt https://dergigi.com/PGP.txt
# import into gpg
gpg --import -q PGP.txt || true
# verify
if ! git verify-tag v"${JAM_VERSION}"; then
  echo -e "${R}The signature(s) for the source code are not good signature. Exiting now.${NC}"
  exit 1
else
  echo -e "${G}The signature(s) for the source code are good signature(s).${NC}"
fi
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### build the jam application
#
echo
echo -e "${Y}Build the JAM application...${NC}"
echo -e "${LB}This can take quite some time!${NC}"
cd "${JAM_DIR}"
# update npm (based on warnings)
npm install -g npm@"${NPM_UPD_VER}"
# build
npm install
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create a jam config file ${JAM_CONF_FILE} and overwrite default app port
#
echo
echo -e "${Y}Write Jam config file ${JAM_CONF_FILE} and overwrite default app port...${NC}"
cat > "${JAM_CONF_FILE}"<< EOF

PORT=3020

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permissions of the jam and ssl dirs for user satoshi
#
echo
echo -e "${Y}Change permissions of ${JAM_DIR} for user ${USER}...${NC}"
chown -R "${USER}":"${USER}" "${JAM_DIR}"
chown -R "${USER}":"${USER}" "${JM_DATA_DIR}"/ssl
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create systemd service file for jmwalletd
#
echo
echo -e "${Y}Create systemd service file for JMwalletd ${JM_WALLETD_SERVICE_FILE}...${NC}"
cat > "${JM_WALLETD_SERVICE_FILE}"<< EOF
#
# systemd unit for JoinMarket API
# /etc/systemd/system/jmwalletd.service
#

[Unit]
Description=JoinMarket API daemon
After=bitcoind.service
Requires=bitcoind.service

[Service]
WorkingDirectory=${JM_DIR}/scripts/
ExecStart=/bin/sh -c '. ${JM_DIR}/jmvenv/bin/activate && python3 jmwalletd.py'
User=satoshi

Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create systemd service file for obwatcher
#
echo
echo -e "${Y}Create systemd service file for OBwatcher ${JM_OBWATCHER_SERVICE_FILE}...${NC}"
cat > "${JM_OBWATCHER_SERVICE_FILE}"<< EOF
#
# systemd unit for JoinMarket OrderBook Watcher
# /etc/systemd/system/obwatcher.service
#

[Unit]
Description=JoinMarket OrderBook Watcher daemon
After=jmwalletd.service
Requires=jmwalletd.service

[Service]
WorkingDirectory=${JM_DIR}/scripts/
ExecStart=/bin/sh -c '. ${JM_DIR}/jmvenv/bin/activate && python3 obwatch/ob-watcher.py --host=127.0.0.1'
User=satoshi

Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create systemd service file for jam
#
echo
echo -e "${Y}Create systemd service file for Jam ${JAM_SERVICE_FILE}...${NC}"
cat > "${JAM_SERVICE_FILE}"<< EOF
#
# systemd unit for JoinMarket WebUI (Jam App)
# /etc/systemd/system/jam.service
#

[Unit]
Description=JoinMarket WebUI daemon - Jam
After=jmwalletd.service obwatcher.service
Requires=jmwalletd.service obwatcher.service

[Service]
WorkingDirectory=${JAM_DIR}
ExecStart=/usr/bin/npm start
User=satoshi

Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### nginx Jam reverse proxy ssl config
#
echo
echo -e "${Y}Write nginx Jam reverse proxy ssl config (${JAM_NGINX_SSL_CONF})...${NC}"
cat > "${JAM_NGINX_SSL_CONF}"<< EOF

upstream jam {
  server 127.0.0.1:3020;
}
server {
  listen ${JAM_SSL_PORT} ssl;
  listen [::]:${JAM_SSL_PORT} ssl;
  proxy_pass jam;
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


echo
echo -e "${Y}Installation all done!${NC}"
echo
echo -e "${LB}Systemd Service (as root or with sudo as user):${NC}"
echo -e " systemctl enable ${JM_WALLETD_SERVICE} - enable service after boot\n" \
        "systemctl start ${JM_WALLETD_SERVICE}  - start JMwalletd API service\n" \
        "systemctl stop ${JM_WALLETD_SERVICE}   - stop JMwalletd API service\n" \
        "systemctl status ${JM_WALLETD_SERVICE} - show service status" | column -t -s "+"
echo
echo -e " systemctl enable ${JM_OBWATCHER_SERVICE} - enable service after boot\n" \
        "systemctl start ${JM_OBWATCHER_SERVICE}  - start OBwatcher service\n" \
        "systemctl stop ${JM_OBWATCHER_SERVICE}   - stop OBwatcher service\n" \
        "systemctl status ${JM_OBWATCHER_SERVICE} - show service status" | column -t -s "+"
echo
echo -e " systemctl enable ${JAM_SERVICE} - enable service after boot\n" \
        "systemctl start ${JAM_SERVICE}  - start Jam service\n" \
        "systemctl stop ${JAM_SERVICE}   - stop Jam service\n" \
        "systemctl status ${JAM_SERVICE} - show service status" | column -t -s "+"
echo
echo -e "${LB}View Log:${NC}"
echo " journalctl -fu ${JM_WALLETD_SERVICE}"
echo " journalctl -fu ${JM_OBWATCHER_SERVICE}"
echo " journalctl -fu ${JAM_SERVICE}"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${JM_DIR} + - JoinMarket base directory\n" \
        "${JM_DATA_DIR} + - JoinMarket data/working dir\n" \
        "${JM_DOWNLOAD_DIR} + - JoinMarket download dir\n" \
        "+\n" \
        "${JM_CONF_FILE} + - JoinMarket config file\n" \
        "+\n" \
        "${JM_WALLETD_SERVICE_FILE} + - JoinMarket API systemd service file\n" \
        "${JM_OBWATCHER_SERVICE_FILE} + - JoinMarket OrderBook watcher systemd service file\n" \
        "${JAM_SERVICE_FILE} + - Jam WebUI systemd service file\n" \
        "+\n" \
        "${JAM_DIR} + - Jam base dir\n" \
        "+\n" \
        "${JAM_CONF_FILE} + - JAM .env config file\n" \
        "+\n" \
        "${JAM_NGINX_SSL_CONF} + - Jam nginx ssl config\n" | column -t -s "+"
echo
echo
echo -e "1) ${LB}You must create a wallet in bitcoin core with bitcoin-cli (while bitcoind is running).${NC}"
echo -e "${LB}This wallet will be used by JoinMarket to store addresses as watch-only. It will use this wallet when it communicates with bitcoin core via rpc calls.${NC}"
echo -e "${LB}The wallet with name${NC} jm_wallet ${LB}is already entered in the joinmarket.cfg config file. Use the following command (as user satoshi) to create it:${NC}"
echo " bitcoin-cli -named createwallet wallet_name=jm_wallet descriptors=false"
echo
echo -e "${LB}See more information here:${NC} https://github.com/JoinMarket-Org/joinmarket-clientserver/blob/master/docs/USAGE.md#setting-core-wallet"
echo
echo -e "2) ${LB}Start the JoinMarket API service:${NC} systemctl start ${JM_WALLETD_SERVICE}"
echo
echo -e "3) ${LB}Start the JoinMarket OrderBook watcher service:${NC} systemctl start ${JM_OBWATCHER_SERVICE}"
echo
echo -e "4) ${LB}Start the Jam WebUI service:${NC} systemctl start ${JAM_SERVICE}"
echo
echo -e "5) ${LB}Open the Jam WebUI page in your browser via the following URL: ${NC}"
echo " https://${LOCAL_IP}:${JAM_SSL_PORT}"
echo

