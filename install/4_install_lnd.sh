#!/bin/bash

#
### download, verify, install Lightning LND
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
echo -e "${Y}This script will download, verify and install Lightning Lnd...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Upgrade system to newest software (apt-get update / apt-get upgrade)"
echo "- Create Lnd download dir in users download dir ${DOWNLOAD_DIR}"
echo "- Download Lnd release files, version ${LND_VERSION}"
echo "- Verify, extract and install the release"
echo "- Create Lnd base dir (.lnd) in ${HOME_DIR}"
echo "- Create and configure Lnd config file (${LND_CONF_FILE})"
echo "- Set Lnd node alias in config (by user interaction)"
echo "- Create systemd ${LND_SERVICE} service file"
echo "- Change permissions for download and base dirs for user ${USER}"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read

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
### create Lnd download dir
#
echo
echo -e "${Y}Create downloads directory for Lnd for user ${USER}...${NC}"
mkdir -p "${LND_DOWNLOAD_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### download what is needed for Lnd
#
echo
echo -e "${Y}Download Lnd release files...${NC}"
cd "${LND_DOWNLOAD_DIR}"
# lnd release
wget -O lnd-linux-amd64-v"${LND_VERSION}".tar.gz \
        https://github.com/lightningnetwork/lnd/releases/download/v"${LND_VERSION}"/lnd-linux-amd64-v"${LND_VERSION}".tar.gz
wget -O manifest-roasbeef-v"${LND_VERSION}".sig \
        https://github.com/lightningnetwork/lnd/releases/download/v"${LND_VERSION}"/manifest-roasbeef-v"${LND_VERSION}".sig
wget -O manifest-v${LND_VERSION}.txt \
        https://github.com/lightningnetwork/lnd/releases/download/v${LND_VERSION}/manifest-v${LND_VERSION}.txt
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### verify the release
#
echo
echo -e "${Y}Verify the release files...${NC}"
# checksum
sha256sum --ignore-missing --check manifest-v"${LND_VERSION}".txt
if [ "$?" -eq 0 ]; then
  echo -e "${G}Verification of release checksum in checksum file: OK${NC}"
else
  echo -e "${R}Verification of release checksum: Not OK${NC}"
  exit
fi
# download gpg key
wget -O roasbeef.asc https://raw.githubusercontent.com/lightningnetwork/lnd/master/scripts/keys/roasbeef.asc
# import into gpg
gpg --import -q roasbeef.asc || true
# verify
gpg --verify manifest-roasbeef-v"${LND_VERSION}".sig manifest-v"${LND_VERSION}".txt
if [ "$?" != 0 ]; then
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
echo -e "${Y}Extract release and install the lnd apps into /usr/local/bin/...${NC}"
cd "${LND_DOWNLOAD_DIR}"
# extract
tar xvfz lnd-linux-amd64-v"${LND_VERSION}".tar.gz
cd lnd-linux-amd64-v"${LND_VERSION}"
# install to /usr/local/bin
install -m 0755 -o root -g root -t /usr/local/bin "${LND_DOWNLOAD_DIR}"/lnd-linux-amd64-v"${LND_VERSION}"/*
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create Lnd base dir
#
echo
echo -e "${Y}Create Lnd base dir (.lnd) in ${HOME_DIR}...${NC}"
mkdir -p "${LND_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create config and write content to the config
#
echo
echo -e "${Y}Create and configure Lnd config file...${NC}"
cat > "${LND_CONF_FILE}"<< EOF
tlsextraip=0.0.0.0
#tlsextraip=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
tlsextraip=127.0.0.1
tlsextradomain=0.0.0.0
tlsautorefresh=true
tlsdisableautofill=true

listen=0.0.0.0:9735
rpclisten=0.0.0.0:10009
restlisten=0.0.0.0:8080

debuglevel=info

maxpendingchannels=5
minchansize=100000
coop-close-target-confs=24
ignore-historical-gossip-filters=true
stagger-initial-reconnect=true
max-channel-fee-allocation=1.
accept-keysend=true
accept-amp=true

gc-canceled-invoices-on-startup=true
gc-canceled-invoices-on-the-fly=true

alias=<your_alias>

bitcoin.active=true
bitcoin.mainnet=true
bitcoin.node=bitcoind
bitcoin.defaultchanconfs=3
bitcoin.basefee=1000
bitcoin.feerate=1

bitcoind.rpchost=127.0.0.1:8332
#bitcoind.rpcuser=<rpc_user>
#bitcoind.rpcpass=<rpc_pass>
bitcoind.rpccookie=${BITCOIN_DIR}/.cookie
bitcoind.zmqpubrawblock=tcp://127.0.0.1:28332
bitcoind.zmqpubrawtx=tcp://127.0.0.1:28333

autopilot.active=false

tor.active=true
tor.v3=true

wtclient.active=true

protocol.wumbo-channels=true
protocol.simple-taproot-chans=false

db.bolt.auto-compact=true
db.bolt.auto-compact-min-age=168h

rpcmiddleware.enable=true
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### set Lnd node alias (by user input)
#
echo
echo -e "${Y}Set Lnd node alias in config...${NC}"
echo -e "${LR}Please enter an ${NC}alias${LR} for the Lnd node and press the ${NC}<enter>${LR} key (can be several words, e.g.: My Lnd Node)...${NC}"
read -r NODE_ALIAS
# replace alias string in lnd.conf
sed -i "s/^alias=.*/alias=${NODE_ALIAS}/g" "${LND_CONF_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create systemd service file and enter content into the service file
#
echo
echo -e "${Y}Create Lnd systemd service file...${NC}"
cat > "${LND_SERVICE_FILE}"<< EOF
# A sample systemd service file for lnd running with a bitcoind service.

[Unit]
Description=Lightning Network Daemon

# Make sure lnd starts after bitcoind is ready
Requires=bitcoind.service
After=bitcoind.service

[Service]
ExecStart=/usr/local/bin/lnd
ExecStop=/usr/local/bin/lncli stop

# Replace these with the user:group that will run lnd
User=${USER}
Group=${USER}

# Try restarting lnd if it stops due to a failure
Restart=on-failure
RestartSec=60

# Type=notify is required for lnd to notify systemd when it is ready
Type=notify

# An extended timeout period is needed to allow for database compaction
# and other time intensive operations during startup. We also extend the
# stop timeout to ensure graceful shutdowns of lnd.
TimeoutStartSec=1200
TimeoutStopSec=3600

####################
# Hardening Measures
####################

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

#
### chown download, .lnd dir for user satoshi
#
echo
echo -e "${Y}Change permissions for download and base dirs for user ${USER}...${NC}"
chown -R "${USER}":"${USER}" "${LND_DOWNLOAD_DIR}"
chown -R "${USER}":"${USER}" "${LND_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Installation all done!${NC}"
echo
echo -e "${LB}Systemd Service (as root or with sudo as user):${NC}"
echo -e " systemctl enable ${LND_SERVICE} + - enable Lnd service after boot\n" \
        "systemctl start ${LND_SERVICE} + - start Lnd service\n" \
        "systemctl stop ${LND_SERVICE} + - stop Lnd service\n" \
        "systemctl status ${LND_SERVICE} + - show Lnd service status" | column -t -s "+"
echo
echo -e "${LB}View Log:${NC}"
echo " journalctl -fu ${LND_SERVICE}"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${LND_DOWNLOAD_DIR} + - Lnd download directory\n" \
        "${LND_DIR} + - Lnd base dir (contains config, certs, macaroon files)\n" \
        "${LND_CONF_FILE} + - Lnd config file\n" \
         "+\n" \
         "${LND_SERVICE_FILE} + - Lnd systemd service file" | column -t -s "+"
echo
echo -e "${LB}Start Lnd via service. Create a wallet with: lncli start${NC}"
echo -e "${LB}Follow the instructions and note down your wallet password and seed words!${NC}"
echo -e "${LB}Unlock the wallet with: lncli unlock (and then entering the wallet password).${NC}"
echo -e "${LB}Each time Lnd is started or restarted you need to unlock manually (if not changed in the config file).${NC}"
echo
echo -e "${LB}To enable Lightning in Mempool, go to mempool backend config (${MEMPOOL_BACKEND_CONF}) ...${NC}"
echo -e "${LB} and change 'ENABLED: false' to true for MAXMIND and LIGHTNING sections.${NC}"
echo -e "${LB}Then restart the mempool service.${NC}"
echo
echo -e "${LB}A guide for Lnd can be found here:${NC}"
echo " https://docs.lightning.engineering/lightning-network-tools/lnd/"
echo
