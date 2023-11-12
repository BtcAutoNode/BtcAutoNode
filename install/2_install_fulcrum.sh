#!/bin/bash

#
### download, verify, install Fulcrum (electrum server)
#

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

# clear screen
clear

#-----------------------------------------------------------------

#
### Check if user really wants to install...or exit
#
echo
echo -e "${Y}This script will download, verify and install Fulcrum...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Upgrade system to newest software (apt update / apt upgrade)"
echo "- Create Fulcrum download dir in users download dir ${DOWNLOAD_DIR}"
echo "- Download Fulcrum release files, version ${FULCRUM_VERSION}"
echo "- Verify, extract and install the release"
echo "- Create Fulcrum base dir (${FULCRUM_DIR}) and write config into it"
echo "- Create Fulcrum data dir (${FULCRUM_DATA_DIR})"
echo "- Create SSL certificates in ${FULCRUM_DIR}"
echo "- Create and configure Fulcrum config file (${FULCRUM_CONF_FILE})"
echo "- Copy application binary files into ${FULCRUM_DIR}"
echo "- Create Fulcrum banner file in ${FULCRUM_DIR}"
echo "- Create systemd ${FULCRUM_SERVICE} service file"
echo "- Change permissions for download, base, data dirs for user ${USER}"
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
echo -e "${Y}Updating the system via apt...${NC}"
apt-get -q update && apt upgrade -y
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create Fulcrum download dir
#
echo
echo -e "${Y}Create downloads directory for Fulcrum for user ${USER}...${NC}"
mkdir -p "${FULCRUM_DOWNLOAD_DIR}"
echo -e "${G}Done.${NC}"

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
wget -O Fulcrum-"${FULCRUM_VERSION}"-sha256sums.txt.asc \
        https://github.com/cculianu/Fulcrum/releases/download/v"${FULCRUM_VERSION}"/Fulcrum-"${FULCRUM_VERSION}"-sha256sums.txt.asc
wget -O Fulcrum-"${FULCRUM_VERSION}"-sha256sums.txt \
        https://github.com/cculianu/Fulcrum/releases/download/v"${FULCRUM_VERSION}"/Fulcrum-"${FULCRUM_VERSION}"-sha256sums.txt
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### verify the release
#
echo
echo -e "${Y}Verify the release files...${NC}"
# checksum
sha256sum --ignore-missing --check Fulcrum-"${FULCRUM_VERSION}"-sha256sums.txt
if [ "$?" -eq 0 ]; then
  echo -e "${G}Verification of release checksum in checksum file: OK${NC}"
else
  echo -e "${R}Verification of release checksum: Not OK${NC}"
  exit
fi
# download gpg key
wget -O calinkey.txt https://raw.githubusercontent.com/Electron-Cash/keys-n-hashes/master/pubkeys/calinkey.txt
# import into gpg
gpg --import -q calinkey.txt
# verify
gpg --verify Fulcrum-"${FULCRUM_VERSION}"-sha256sums.txt.asc 2>&1 >/dev/null | grep 'Good Signature'
if [ "$?" = 0 ]; then
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
echo -e "${Y}Extract release...${NC}"
cd "${FULCRUM_DOWNLOAD_DIR}"
# extract
tar xvfz Fulcrum-"${FULCRUM_VERSION}"-x86_64-linux.tar.gz
cd Fulcrum-"${FULCRUM_VERSION}"-x86_64-linux
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create Fulcrum base dir and Fulcrum data dir
#
echo
echo -e "${Y}Create Fulcrum base and data dir (fulcrum / fulcrum_db) in ${HOME_DIR}...${NC}"
mkdir -p "${FULCRUM_DIR}"
mkdir -p "${FULCRUM_DATA_DIR}"
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

#
### create ssl certs
#
echo
echo -e "${Y}Create SSL certificates into the Fulcrum dir...${NC}"
# cd into user's Fulcrum dir
cd "${FULCRUM_DIR}"
# create ssl keys for use in Fulcrum
openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout key.pem -out cert.pem -subj "/C=/ST=/L=/O=/OU=/CN=localhost"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create config and write content to the config
#
echo
echo -e "${Y}Create and configure fulcrum config file...${NC}"
cat > "${FULCRUM_CONF_FILE}"<< EOF
#
# Fulcrum config file
# Example config: https://raw.githubusercontent.com/cculianu/Fulcrum/master/doc/fulcrum-example-config.conf
#

# Bitcoin Core settings
bitcoind = 127.0.0.1:8332
rpccookie = ${BITCOIN_DIR}/.cookie

# Fulcrum server settings
datadir = ${FULCRUM_DATA_DIR}
cert = ${FULCRUM_DIR}/cert.pem
key = ${FULCRUM_DIR}/key.pem
tcp = 0.0.0.0:50001
ssl = 0.0.0.0:50002
polltime = 2.0
peering = false

# Interfaces
admin = 127.0.0.1:8000
stats = 127.0.0.1:8080

# Banner path
banner = ${FULCRUM_DIR}/banner.txt

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create banner file banner.txt
#
echo
echo -e "${Y}Create fulcrum banner file...${NC}"
cat > "${FULCRUM_DIR}"/banner.txt<< EOF

 mmmmmm        ""#
 #      m   m    #     mmm    m mm  m   m  mmmmm 
 #mmmmm #   #    #    #"  "   #"  " #   #  # # # 
 #      #   #    #    #       #     #   #  # # # 
 #      "mm"#    "mm  "#mm"   #     "mm"#  # # # 

server version: \${SERVER_VERSION}
bitcoind version: \${DAEMON_VERSION}
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create Fulcrum service file and enter content into the service file
#
echo
echo -e "${Y}Create Fulcrum systemd service file...${NC}"
cat > "${FULCRUM_SERVICE_FILE}"<< EOF
#
# Fulcrum systemd service file
# Example service file: https://raw.githubusercontent.com/cculianu/Fulcrum/master/contrib/rpm/fulcrum.service
#
[Unit]
Description=Fulcrum SPV server for Bitcoin Cash
Wants=network-online.target
After=network-online.target bitcoind.service

[Service]
Type=simple
User=${USER}
Group=${USER}
LimitNOFILE=20000:32767
ExecStart=${FULCRUM_DIR}/Fulcrum -S --datadir ${FULCRUM_DATA_DIR} ${FULCRUM_CONF_FILE}

[Install]
WantedBy=multi-user.target

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### chown download, fulcrum and fulcrum_db dir for user satoshi
#
echo
echo -e "${Y}Change permissions for download, base, data dirs for user ${USER}...${NC}"
chown -R "${USER}":"${USER}" "${FULCRUM_DOWNLOAD_DIR}"
chown -R "${USER}":"${USER}" "${FULCRUM_DIR}"
chown -R "${USER}":"${USER}" "${FULCRUM_DATA_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Installation all done!${NC}"
echo
echo -e "${LB}Systemd Service (as root or with sudo as user):${NC}"
echo -e " systemctl enable ${FULCRUM_SERVICE} + - enable Fulcrum service after boot\n" \
       "systemctl start ${FULCRUM_SERVICE} + - start Fulcrum service\n" \
       "systemctl stop ${FULCRUM_SERVICE} + - stop Fulcrum service\n" \
       "systemctl status ${FULCRUM_SERVICE} + - show Fulcrum service status" | column -t -s "+"
echo
echo -e "${LB}View Log:${NC}"
echo " journalctl -fu ${FULCRUM_SERVICE}"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${FULCRUM_DOWNLOAD_DIR} + - Fulcrum download directory\n" \
      "${FULCRUM_DIR} + - Fulcrum base dir (contains apps, config, certs)\n" \
      "${FULCRUM_DATA_DIR} + - Fulcrum data dir (contains the indexes)\n" \
      "${FULCRUM_CONF_FILE} + - Fulcrum config file\n" \
      "+\n" \
      "/etc/systemd/system/${FULCRUM_SERVICE} + - Fulcrum systemd service file" | column -t -s "+"
echo


