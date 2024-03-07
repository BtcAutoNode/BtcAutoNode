#!/bin/bash

#
### upgrade sparrow terminal (if possible)
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
else
  # set PATH env var for sbin and bin dirs (su root fails the installation)
  export PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
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
### print info
#
echo
echo -e "${Y}This script will check for a new Sparrow version and upgrade if possible...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Check latest Github version against current running version"
echo "- Exit if no new version is available"
echo "- Exit if Sparrow is still active"
echo "- Request user to confirm to upgrade to the new version (by user interaction)"
echo "- Download new Sparrow release files"
echo "- Verify, extract and install the release"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
### check for new version
#
echo
echo -e "${Y}Check Github version and compare to running version...${NC}"
latest_version=$(curl -sL https://github.com/sparrowwallet/sparrow/releases/latest | grep "<title>Release" | cut -d ' ' -f 4)
running_version=$(Sparrow --version | cut -d ' ' -f 3)
echo "Latest version on Github : ${latest_version}"
echo "Current version running  : ${running_version}"
echo

# check if a version string is empty . If so, exit script
if [ "$latest_version" = "" ]; then
  echo -e "${R}Latest version not available...exiting. Github page not reachable?${NC}"
  echo
  exit 1
elif [ "$running_version" = "" ]; then
  echo -e "${R}Current version not available...exiting. Is the app installed?${NC}"
  echo
  exit 1
fi

# compare
if [ "$latest_version" = "$running_version" ]; then
  echo -e "${R}No new version available...exiting${NC}"
  echo
  exit
else
  echo -e "${G}New version ${latest_version} available...possible to upgrade${NC}"
fi

# replace so existing commands can be used
SPARROW_VERSION="${latest_version}"

#-----------------------------------------------------------------

#
### check if sparrow is still active (exit if so)
#
sparrow_proc=$(pidof Sparrow) || true
if [ ! -z "$sparrow_proc" ]; then
  echo -e "${R}Sparrow still running...exiting!${NC}"
  echo
  echo -e "${LB}Stop Sparrow via:${NC}"
  echo " Entering the tmux session via tmux a and then closing Sparrow."
  echo " Use: exit <enter> afterwards to leave the tmux session also."
  echo
  exit
else
  echo -e "${G}Sparrow not running${NC}"
fi

#----------------------------------------------------------------

#
### ask to go on or exit
#
echo
echo -e "${LR}Do you really want to upgrade to the newer version??${NC}"
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

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
gpg --import -q pgp_keys.asc || true
gpg --verify sparrow-"${SPARROW_VERSION}"-manifest.txt.asc
if [ "$?" != 0 ]; then
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

echo
echo -e "${Y}Upgrade all done!${NC}"
echo
echo -e "${LB}Start Sparrow again via:${NC}"
echo " Create a tmux session via: tmux new -s sparrow_server"
echo " Then use: Sparrow <enter> and open your wallets again."
echo " Start the mixing, lock the wallets and detach via: ctrl-b, then d"
echo

