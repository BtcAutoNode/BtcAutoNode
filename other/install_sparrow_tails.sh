#!/bin/bash

#
# Script is used to install the desktop Sparrow Wallet app in TailsOS (Persistent directory)
#
#
# The Persistent storage need to be enabled. Find information here:
#   https://tails.net/doc/persistent_storage/index.en.html
#
# Download/copy this script into the Persistent directory and execute from there as user amnesia.
#

#------------------------------------------------------
# config
## newest version is read from sparrow github automatically. Change if you want to install a specific version:
## e.g.: SPARROW_VERSION="1.8.2"
USER="amnesia"
PERSISTENT_DIR="/home/${USER}/Persistent"
SPARROW_VERSION=$(curl -sL https://github.com/sparrowwallet/sparrow/releases/latest | grep "<title>Release" | cut -d ' ' -f 4)
DOWNLOAD_DIR="${PERSISTENT_DIR}/downloads"
SPARROW_APP_DIR="${PERSISTENT_DIR}/Sparrow"
SPARROW_DATA_DIR="${PERSISTENT_DIR}/.sparrow"
SPARROW_START_SCRIPT="${PERSISTENT_DIR}/start_sparrow.sh"
#------------------------------------------------------
# bash colors
Y="\033[1;33m"    # is Yellow's ANSI color code
G="\033[0;32m"    # is Green's ANSI color code
R="\033[0;31m"    # is Red's ANSI color code
LB="\033[1;34m"   # is L-Brown's ANSI color code
LR="\033[1;31m"   # is L-Red's ANSI color code
NC="\033[0m"      # No Color
#------------------------------------------------------

# fail if a command fails and exit
set -e

# clear screen
clear

#------------------------------------------------------

#
### check if user is amnesia, otherwise exit
#
user=$(id -u -n)
if [ "$user" != "$USER" ]; then
  echo
  echo -e "${R}Please run the installation script as user amnesia!${NC}"
  echo
  exit
fi

#-----------------------------------------------------------------

#
### Check if user really wants to install...or exit
#
echo
echo -e "${Y}This script will install Sparrow Wallet into the Persistent directory...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Create downloads, Sparrow app and Sparrow data dirs in the Persistent directory"
echo "- Download the release from sparrowwallet.com/download/ into the downloads folder"
echo "- Verify the release file(s)"
echo "- Extract the release and move the extracted content to the persistent Sparrow app dir"
echo "- Create a start script in the Persistent directory to launch the Sparrow Wallet app"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

# clear screen
clear

#-----------------------------------------------------------------

# create directories in Persistence
# download directory
echo
echo -e "${Y}Create downloads, Sparrow app and data directories in Persistent dir...${NC}"
mkdir -p "${DOWNLOAD_DIR}"
# sparrow application directory
mkdir -p "${SPARROW_APP_DIR}"
# sparrow Wallet data directory
mkdir -p "${SPARROW_DATA_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

# download files into download directory
echo
echo -e "${Y}Download the release files from Sparrowwallet.com downloads page...${NC}"
cd "${DOWNLOAD_DIR}"
wget -O sparrow-"${SPARROW_VERSION}"-x86_64.tar.gz \
        https://github.com/sparrowwallet/sparrow/releases/download/"${SPARROW_VERSION}"/sparrow-"${SPARROW_VERSION}"-x86_64.tar.gz
wget -O sparrow-"${SPARROW_VERSION}"-manifest.txt \
        https://github.com/sparrowwallet/sparrow/releases/download/"${SPARROW_VERSION}"/sparrow-"${SPARROW_VERSION}"-manifest.txt
wget -O sparrow-"${SPARROW_VERSION}"-manifest.txt.asc \
        https://github.com/sparrowwallet/sparrow/releases/download/"${SPARROW_VERSION}"/sparrow-"${SPARROW_VERSION}"-manifest.txt.asc
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

# verify the release
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
# import into gpg || true
gpg --import -q pgp_keys.asc
gpg --verify sparrow-"${SPARROW_VERSION}"-manifest.txt.asc 2>&1 >/dev/null | grep 'Good signature'
if [ "$?" != 0 ]; then
  echo -e "${R}The signature(s) for the downloaded file are not good signature. Exiting now.${NC}"
  exit 1
else
  echo -e "${G}The signature(s) for the downloaded file are good signature(s).${NC}"
fi
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

# extract release file
echo
echo -e "${Y}Extract release, move content to the Sparrow app dir in the Persistent dir...${NC}"
tar xfz sparrow-"${SPARROW_VERSION}"-x86_64.tar.gz
# move files into Sparrow application dir
mv "${DOWNLOAD_DIR}"/Sparrow/* "${SPARROW_APP_DIR}"
rmdir "${DOWNLOAD_DIR}"/Sparrow/
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

# create start script in Persistent dir and make it executable
echo
echo -e "${Y}Create start script in the Persistent directory...${NC}"
cat > "${SPARROW_START_SCRIPT}"<< EOF

#!/bin/bash
${SPARROW_APP_DIR}/bin/Sparrow -d ${SPARROW_DATA_DIR}

EOF

# make start script executable
chmod +x "${SPARROW_START_SCRIPT}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Installation all done!${NC}"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${DOWNLOAD_DIR} + - Persistent download dir (contains release files)\n" \
        "${SPARROW_APP_DIR} + - Persistent Sparrow application dir (app binaries and libs)\n" \
        "${SPARROW_DATA_DIR} + - Persistent Sparrow data dir (log and config file, wallets, ...)\n" \
        "+\n" \
        "${SPARROW_START_SCRIPT} + - Start script to launch the application" | column -t -s "+"
echo
echo -e "${LB}You can now start Sparrow Wallet via:${NC}"
echo "  cd /home/amnesia/Persistent"
echo "  ./start_sparrow.sh"
echo
