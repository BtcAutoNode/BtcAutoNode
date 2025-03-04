#!/bin/bash

#
### download, verify, install bitcoind
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
echo -e "${Y}This script will download, verify and install Bitcoind...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Upgrade system to newest software (apt-get update / apt-get upgrade)"
echo "- Create Bitcoin download dir in users download dir ${DOWNLOAD_DIR}"
echo "- Download Bitcoin release files, version ${BITCOIN_VERSION}"
echo "- Verify, extract and install the release"
echo "- Create Bitcoin base dir (${BITCOIN_DIR}) and write config into it"
echo "- Create rpc-auth string from rpcuser/rpcpass (by user interaction) and write to config"
echo "- Change permissions of Bitcoin base and download dir for user ${USER}"
echo "- Create systemd ${BITCOIN_SERVICE} service file"
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
### create download dir
#
echo
echo -e "${Y}Create downloads directory for Bitcoin for user ${USER}...${NC}"
mkdir -p "${BITCOIN_DOWNLOAD_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### download what is needed for bitcoind
#
echo
echo -e "${Y}Download bitcoind release files...${NC}"
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
if sha256sum --ignore-missing --check --status SHA256SUMS; then
  echo -e "${G}Verification of release checksum in checksum file: OK${NC}"
else
  echo -e "${R}Verification of release checksum: Not OK${NC}"
  exit
fi
# download the repo with the builder keys
# info: https://bitcoincore.org/en/download/
rm -rf guix.sigs
git clone https://github.com/bitcoin-core/guix.sigs
# import into gpg
gpg --import -q guix.sigs/builder-keys/* || true
# verify
if ! gpg --verify SHA256SUMS.asc; then
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
echo -e "${Y}Extract release and install the bitcoind apps into /usr/local/bin/...${NC}"
cd "${BITCOIN_DOWNLOAD_DIR}"
tar xfz bitcoin-"${BITCOIN_VERSION}"-x86_64-linux-gnu.tar.gz
install -m 0755 -o root -g root -t /usr/local/bin "${BITCOIN_DOWNLOAD_DIR}"/bitcoin-"${BITCOIN_VERSION}"/bin/*
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create bitoin base directory
#
echo
echo -e "${Y}Create bitcoind base dir .bitcoin...${NC}"
mkdir -p "${BITCOIN_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create config and write content to the config
#
echo
echo -e "${Y}Create and configure bitcoind config file...${NC}"
cat > "${BITCOIN_CONF_FILE}"<< EOF
#
# Bitcoind config file
#

# Bitcoin daemon
server=1
txindex=1
daemon=1

# Connections
rpcport=8332
rpcauth=<rpc user>:<auth hash>
rpcbind=127.0.0.1
rpcallowip=127.0.0.1
# For issues with apps together with bitcoin core v28.0 (e.g. lnd):
# (comment out for bitcoin core versions other than v28.0)
deprecatedrpc=warnings

zmqpubrawblock=tcp://127.0.0.1:28332
zmqpubrawtx=tcp://127.0.0.1:28333
zmqpubhashblock=tcp://127.0.0.1:8433
zmqpubhashblock=tcp://127.0.0.1:28334
zmqpubsequence=tcp://127.0.0.1:28335

whitelist=127.0.0.1

# Network / tor
listen=1
onlynet=onion
# Use separate SOCKS5 proxy to reach peers via Tor
proxy=127.0.0.1:9050
bind=127.0.0.1
# allow inbound peers in bitcoin core versions 28+
bind=127.0.0.1:8334=onion

# Don't let bitcoin core get peers using clearnet dns servers
dnsseed=0
dns=0

# Optimizations
maxconnections=30
# maxuploadtarget=5000
# enable compact-filters BIP158 service, so that BIP157 can be used
blockfilterindex=1
# serve compact block filters to peers per BIP157 (default: 0)
peerblockfilters=1
# accept transaction replace-by-fee without requiring replaceability
mempoolfullrbf=0

# Bisq
peerbloomfilters=1

# Optimizations only for the initial sync of the blockchain
# Comment out after initial sync and restart bitcoind (dbcache default is then 450MB)
#dbcache=2000
#blocksonly=1

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### add rpc-auth string to config
### query user to enter rpcuser and rpcpass
#
echo
echo -e "${Y}Create rpc-auth string for RPC protocol authentication$...${NC}"
echo "An rpc-auth string is now been created based on your user input. This will be added into the bitcoind config to allow rpc communiation."
echo -e "${LR}Please enter an ${NC}rpcuser${LR} name and press the ${NC}<enter>${LR} key:${NC}"
read -r RPCUSER
echo -e "${LR}Please enter an ${NC}rpcpass${LR} and press the ${NC}<enter>${LR} key:${NC}"
read -r RPCPASS
rpcoutput=$(python3 "${BITCOIN_DOWNLOAD_DIR}/rpcauth.py" "${RPCUSER}" "${RPCPASS}" | sed -n '2p')
# replace rpcauth string in bitcoin.config
sed -i "s/^rpcauth=.*/${rpcoutput}/g" "${BITCOIN_CONF_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### request user to note down rpcuser and rpcpass
#
echo
echo -e "${LR}Note down ${NC}rpcuser / rpcpass${LR} just entered as they are needed later!! Press ${NC}<enter>${LR} key to go on:${NC}"
read -r

#-----------------------------------------------------------------

#
### chown downloads and bitcoin dir for user
#
echo
echo -e "${Y}Chown downloads and bitcoin base dir for users permissions...${NC}"
chown -R "${USER}":"${USER}" "${BITCOIN_DOWNLOAD_DIR}"
chown -R "${USER}":"${USER}" "${BITCOIN_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create systemd service file and enter content into the service file
#
echo
echo -e "${Y}Create bitcoind systemd service file...${NC}"
cat > "${BITCOIN_SERVICE_FILE}"<< EOF
[Unit]
Description=Bitcoin daemon
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/bitcoind -daemon \\
                            -pid=/run/bitcoind/bitcoind.pid \\
                            -conf=/home/${USER}/.bitcoin/bitcoin.conf \\
                            -datadir=/home/${USER}/.bitcoin

ExecStop=/usr/local/bin/bitcoin-cli stop

# Process management
####################
Type=forking
PIDFile=/run/bitcoind/bitcoind.pid

Restart=on-failure
TimeoutStartSec=infinity
TimeoutStopSec=600
      
# Directory creation and permissions
####################################
User=${USER}
UMask=0027

# /run/bitcoind
RuntimeDirectory=bitcoind
RuntimeDirectoryMode=0710

# Hardening measures
####################
# Provide a private /tmp and /var/tmp.
PrivateTmp=true

# Mount /usr, /boot/ and /etc read-only for the process.
ProtectSystem=full

# Disallow the process and all of its children to gain
# new privileges through execve().
NoNewPrivileges=true

# Use a new /dev namespace only populated with API pseudo devices
# such as /dev/null, /dev/zero and /dev/random.
PrivateDevices=true

# Deny the creation of writable and executable memory mappings.
MemoryDenyWriteExecute=true

[Install]
WantedBy=multi-user.target
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Installation all done!${NC}"
echo
echo -e "${LB}Systemd Service (as root or with sudo as user ${USER}):${NC}"
echo -e " systemctl enable ${BITCOIN_SERVICE} + - enable Bitcoin service after boot\n" \
       "systemctl start ${BITCOIN_SERVICE} + - start Bitcoin service\n" \
       "systemctl stop ${BITCOIN_SERVICE} + - stop Bitcoin service\n" \
       "systemctl status ${BITCOIN_SERVICE} + - show Bitcoin service status" | column -t -s "+"
echo
echo -e "${LB}View Log:${NC}"
echo " tail -f ${BITCOIN_LOG_FILE}"
echo " journalctl -fu ${BITCOIN_SERVICE}"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${BITCOIN_DOWNLOAD_DIR} + - Bitcoin download directory\n" \
       "${BITCOIN_DIR} + - Bitcoin base dir (data dir --> contains log, config, blockchain/index directories)\n" \
       "${BITCOIN_CONF_FILE} + - Bitcoin config file\n" \
       "${BITCOIN_LOG_FILE} + - Bitcoin log file\n" \
       "+\n" \
        "/usr/local/bin + - Bitcoin applications\n" \
        "+\n" \
        "/etc/systemd/system/${BITCOIN_SERVICE} + - Bitcoind systemd service file\n" \
        "/etc/tor/torrc + - tor config file\n" \
        "/etc/tor/torsocks + - tor socks proxy config file" | column -t -s "+"
echo

