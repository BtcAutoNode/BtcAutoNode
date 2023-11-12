#!/bin/bash

#
### downdload, verify, install Sparrow Wallet terminal/server
#

#-----------------------------------------------------------------

#
### check if CONFIG file is there, otherwise exit
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
echo -e "${Y}This script will install Sparrow Wallet terminal/server...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Download of the release from sparrowwallet.com/download/"
echo "- Verify the release file"
echo "- Extract release and move extracted folder to /opt/Sparrow"
echo "- Create symbolic link in /usr/local/bin to Sparrow application in /opt"
echo "- Create .sparrow base dir in ${USER} home dir (${HOME_DIR})"
echo "- Edit config file in .sparrow to connect to fulcrum ssl"
echo "- Change permission of Sparrow download and base dir for ${USER}"
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
### create download dir
#
echo
echo -e "${Y}Create downloads directory for Sparrow for user ${USER}...${NC}"
mkdir -p "${SPARROW_DOWNLOAD_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### download (and overwrite) what is needed for sparrow terminal
#
echo
echo -e "${Y}Download Sparrow terminal release files...${NC}"
cd "${SPARROW_DOWNLOAD_DIR}"
# sparrow terminal release
wget -O sparrow-server-"${SPARROW_VERSION}"-x86_64.tar.gz \
        https://github.com/sparrowwallet/sparrow/releases/download/"${SPARROW_VERSION}"/sparrow-server-"${SPARROW_VERSION}"-x86_64.tar.gz
wget -O sparrow-"${SPARROW_VERSION}"-manifest.txt \
        https://github.com/sparrowwallet/sparrow/releases/download/"${SPARROW_VERSION}"/sparrow-"${SPARROW_VERSION}"-manifest.txt
wget -O sparrow-"${SPARROW_VERSION}"-manifest.txt.asc \
        https://github.com/sparrowwallet/sparrow/releases/download/"${SPARROW_VERSION}"/sparrow-"${SPARROW_VERSION}"-manifest.txt.asc
echo -e "${G}Done.${NC}"


#-----------------------------------------------------------------

#
### verify the release
#
echo
echo -e "${Y}Verify the release files...${NC}"
# checksum
sha256sum --ignore-missing --check --status sparrow-"${SPARROW_VERSION}"-manifest.txt 
if [ "$?" -eq 0 ]; then
  echo -e "${G}Verification of release checksum in checksum file: OK${NC}"
else
  echo -e "${R}Verification of release checksum: Not OK${NC}"
  exit
fi
# download some gpg keys
wget -O pgp_keys.asc https://keybase.io/craigraw/pgp_keys.asc
# import into gpg
gpg --import -q pgp_keys.asc
gpg --verify sparrow-"${SPARROW_VERSION}"-manifest.txt.asc 2>&1 >/dev/null | grep 'Good Signature'
if [ "$?" = 0 ]; then
  echo -e "${R}The signature(s) for the downloaded file are not good signature. Exiting now.${NC}"
  exit 1
else
  echo -e "${G}The signature(s) for the downloaded file are good signature(s).${NC}"
fi
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### extract and move aplication folder into /opt/Sparrow and link to /usr/local/bin
#
echo
echo -e "${Y}Extract release, move to /opt and install the sparrow app into /usr/local/bin/...${NC}"
cd "${SPARROW_DOWNLOAD_DIR}"
echo -e "${LB}Extract release file${NC}"
tar xfz sparrow-server-"${SPARROW_VERSION}"-x86_64.tar.gz
# move folder to /opt
echo -e "${LB}Move extracted folder to /opt${NC}"
# delete /opt/Sparrow if it does exist
rm -rf /opt/Sparrow
mv "${SPARROW_DOWNLOAD_DIR}/Sparrow" /opt
# create symbolic link in /usr/local/bin
echo -e "${LB}Create symbolic link in /usr/local/bin to Sparrow app in /opt${NC}"
ln -sf "${SPARROW_APP_DIR}"/bin/Sparrow "${SPARROW_SYM_LINK}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create sparrow base dir structure in the users home dir
#
echo
echo -e "${Y}Create sparrow base dir structure in ${USER} home dir${NC}"
echo -e "${LB}Create .sparrow folder in user home dir${NC}"
mkdir -p "${SPARROW_DIR}"
echo -e "${LB}Create config and log files${NC}"
touch "${SPARROW_CONF_FILE}"
touch "${SPARROW_LOG_FILE}"
echo -e "${LB}Create directories${NC}"
mkdir -p "${SPARROW_DIR}/certs"
mkdir -p "${SPARROW_DIR}/wallets"
mkdir -p "${SPARROW_DIR}/wallets/backup"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create config and write content to the config
#
echo
echo -e "${Y}Create and configure sparrow terminal config file...${NC}"
cat > "${SPARROW_CONF_FILE}"<< EOF
{
  "mode": "ONLINE",
  "bitcoinUnit": "AUTO",
  "unitFormat": "COMMA",
  "fiatCurrency": "EUR",
  "exchangeSource": "COINGECKO",
  "loadRecentWallets": true,
  "validateDerivationPaths": true,
  "groupByAddress": true,
  "includeMempoolOutputs": true,
  "notifyNewTransactions": true,
  "checkNewVersions": true,
  "openWalletsInNewWindows": false,
  "hideEmptyUsedAddresses": false,
  "showTransactionHex": true,
  "showLoadingLog": true,
  "showAddressTransactionCount": false,
  "showDeprecatedImportExport": false,
  "signBsmsExports": false,
  "preventSleep": false,
  "recentWalletFiles": [
  ],
  "keyDerivationPeriod": 4305,
  "dustAttackThreshold": 1000,
  "enumerateHwPeriod": 30,
  "serverType": "ELECTRUM_SERVER",
  "useLegacyCoreWallet": false,
  "electrumServer": "ssl://127.0.0.1:50002|fulcrum ssl",
  "recentElectrumServers": [
  ],
  "useProxy": true,
  "proxyServer": "127.0.0.1:9050",
  "autoSwitchProxy": true,
  "maxServerTimeout": 34,
  "maxPageSize": 100,
  "usePayNym": false,
  "sameAppMixing": false
}
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### chown downloads and sparrow base dir for user
#
echo
echo -e "${Y}Chown downloads and sparrow base dir for users permissions...${NC}"
chown -R "${USER}":"${USER}" "${SPARROW_DOWNLOAD_DIR}"
chown -R "${USER}":"${USER}" "${SPARROW_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Installation all done!${NC}"
echo
echo -e "${LB}User for the applications:${NC}"
echo -e " Sparrow dir: + - ${SPARROW_DIR} (config/wallets/log)\n" \
        "Sparrow download dir: + - ${SPARROW_DOWNLOAD_DIR}" | column -t -s "+"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${SPARROW_CONF_FILE} + - Sparrow config file\n" \
        "${SPARROW_LOG_FILE} + - Sparrow log file\n" \
        "+\n" \
        "${SPARROW_APP_DIR} + - Sparrow installation dir\n" \
        "${SPARROW_SYM_LINK} + - Sparrow user executable link" | column -t -s "+"
echo
echo
echo -e "${LB}If you have an existing hot wallet for mixing, copy the ${NC}*.mv.db${LB} file into the ${NC}.sparrow/wallets${LB} folder.${NC}"
echo
echo -e "${LB}Start a tmux session (to keep app running after logout): ${NC}tmux new -s sparrow_server${NC}"
echo -e "${LB}Then execute the Sparrow app: ${NC}Sparrow${NC}"
echo -e "${LB}Check that you are connected to your node in the Preferences menu.${NC}"
echo
echo -e "${LB}Check how mixing works in the SparrowWallet docs:${NC}"
echo " https://www.sparrowwallet.com/docs/mixing-whirlpool.html"
echo
echo -e "${LB}To leave and let the Sparrow app open in background for continous mixing...${NC}"
echo -e "${LB} lock your wallet(s) via menu, then press ${NC}<ctrl-b>${LB}, release fingers and then press ${NC}<d>${LB}.${NC}"
echo -e "${LB}The next time you want to access the running session, type: ${NC}tmux a${LB} (and later leave the same way).${NC}"
echo
echo -e "${LB}If you want to close Sparrow, enter the tmux session and select ${NC}Quit${LB} from the Sparrow menu.${NC}"
echo -e "${LB}Then ${NC}exit${LB} to close the tmux session.${NC}"
echo

