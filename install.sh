#!/bin/bash

# script downloads the repository and provides a simple menu to install several options available

#-----------------------------------------------------------------

REPO_URL="https://github.com/BtcAutoNode/BtcAutoNode"
REPO_DIR="btcautonode"

# bash colors
# https://www.shellhacks.com/bash-colors/
# bash colors
G="\033[0;32m"    # is Green's ANSI color code
LR="\033[1;31m"   # is L-Red's ANSI color code
Y="\033[1;33m"    # is Yellow's ANSI color code
LB="\033[1;34m"   # is L-Brown's ANSI color code
NC="\033[0m"      # No Color

#-----------------------------------------------------------------

clear

#
### check if root, otherwise exit
#
echo
if [ "$EUID" -ne 0 ]; then
  echo -e "${R}Please run the installation script as root!${NC}"
  exit
fi

#-----------------------------------------------------------------

echo
echo -e "${Y}########################################################################${NC}"
echo
echo "                  ┏┓ ╺┳╸┏━╸┏━┓╻ ╻╺┳╸┏━┓┏┓╻┏━┓╺┳┓┏━╸   "
echo "                  ┣┻┓ ┃ ┃  ┣━┫┃ ┃ ┃ ┃ ┃┃┗┫┃ ┃ ┃┃┣╸    "
echo "                  ┗━┛ ╹ ┗━╸╹ ╹┗━┛ ╹ ┗━┛╹ ╹┗━┛╺┻┛┗━╸   "
echo
echo -e "${Y}########################################################################${NC}"
echo
echo -e "${Y}  Install script checks if git is available  and installs it if not.${NC}"
echo -e "${Y}  Then the repository will be cloned/updated into ${REPO_DIR}.${NC}"
echo
echo -e "${Y}########################################################################${NC}"
echo

echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#
### update / upgrade system
#
echo
echo -e "${Y}Updating the system via apt-get...${NC}"
apt-get -q update && apt-get upgrade -y
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### install git if not already available
#
echo
if ! git --version &>/dev/null; then
  echo -e "${Y}Git not available...installing via apt-get...${NC}"
  apt-get install git -y
else
  echo -e "${Y}Git already available${NC}"
fi

#-----------------------------------------------------------------

#
### clone the repository or update if already available
#
echo
if [ ! -d "${REPO_DIR}" ] ; then
    echo -e "${Y}Cloning the repository into ${REPO_DIR}${NC}"
    git clone "${REPO_URL}" "${REPO_DIR}"
else
    echo -e "${Y}Updating the repository in ${REPO_DIR}${NC}"
    (
    cd "$REPO_DIR" || { echo "cd repo_dir failed"; exit 1; }
    git fetch --all
    git reset --hard origin/master
    )
fi

#-----------------------------------------------------------------

#
### check if repo clone/update was successful (or exit)
#
GIT_UPD_OK="$?"
if [ "$GIT_UPD_OK" -ne 0 ]; then
  echo -e "${LR}Git clone/update did not work...exiting${NC}"
  exit 1
else
  echo -e "${LB}Repository cloned/updated.${NC}"
fi

#-----------------------------------------------------------------

#
### create symbolic links for config in install/uninstall dirs
#
ln -sf "../CONFIG" "${REPO_DIR}/install/CONFIG"
ln -sf "../CONFIG" "${REPO_DIR}/uninstall/CONFIG"
ln -sf "../CONFIG" "${REPO_DIR}/upgrade/CONFIG"

#-----------------------------------------------------------------

#
### change file permissions
#
echo
echo -e "${Y}Changing file permissions for executing the scripts${NC}"
find "${REPO_DIR}" -name "*.sh" -exec chmod +x {} \;

#-----------------------------------------------------------------

echo
echo "------------------------------------------------------------------------"
echo

#-----------------------------------------------------------------

#
### user instructions
#
echo
echo -e "${LB}Cd into ${NC}'${REPO_DIR}/install'${LB} or ${NC}'${REPO_DIR}/uninstall'${LB} dirs...${NC}"
echo -e "${LB} and execute individual scripts via ${NC}./<script_name>.sh${NC}"
echo
echo -e "${LB}Start with ${NC}./0_install_system.sh${LB} and follow screen instructions.${NC}"
echo -e "${LB}Then install ${NC}bitcoind, fulcrum, mempool${LB} or what else may be needed.${NC}"
echo

#-----------------------------------------------------------------

echo
echo "------------------------------------------------------------------------"
echo

#-----------------------------------------------------------------
