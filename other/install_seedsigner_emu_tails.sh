#!/bin/bash

#
# Script is used to install the SeedSigner-Emulator app in TailsOS (Persistent directory)
# (Allows to execute the SeedSigner app on a PC or Laptop for testing purposes)
# (Works best in a dark terminal theme)
#
# Python >= 3.10 needed (tested in Tails-OS 6.8.1)
#
# Info SeedSigner (in Github):
#   https://github.com/SeedSigner/seedsigner
#
# Info SeedSigner Emulator (in Github):
#   https://github.com/enteropositivo/seedsigner-emulator
#
#
# The TailsOS Persistent storage needs to be enabled. Find information here:
#   https://tails.net/doc/persistent_storage/index.en.html
#
# An Administrator password (sudo password) needs to be enabled. Find information here:
#   https://tails.net/doc/first_steps/welcome_screen/administration_password/index.en.html
#
#
# Download/copy this script into the Persistent directory and execute from there as user amnesia:
#
#   As user amnesia:
#   cd /home/amnesia/Persistent
#   wget https://raw.githubusercontent.com/BtcAutoNode/BtcAutoNode/master/other/install_seedsigner_emu_tails.sh
#   chmod +x install_seedsigner_emu_tails.sh
#   ./install_seedsigner_emu_tails.sh
#
# Everything will be cloned and downloaded into /home/amnesia/Persistent/Seedsigner
# (Uninstall: just delete this folder)
#
# During installation a small black popup window will show up at the top of the screen several times asking
# if installed software shall be installed once or for every start of TailsOS. Click "Always' here.
#
# After installation start the SeedSigner-Emulator via script ./start_seedsigner_emu.sh from /home/amnesia/Persistent
# or via the app entry in the Applications menu.
#
#
# Should look like this:
# /home/amnesia/Persistent/
#   start_seedsigner_emu.sh (start script, start app with this)
#   Seedsigner/
#     venv/
#       bin/  (python3/pip3 apps)
#     seedsigner/
#       src/
#         main.py   (SeedSigner main project file)
#
#
# To see an application shortcut in the Applications menu, you need to activate the dotfiles. When persistent storage was activated,
# on the Desktop go to Applications --> Tails --> Persistent Storage and activate it from there (switch on). Next boot this is still 
# activated and the SeedSigner-Emulator app icon can be seen in the Applications menu.
#
#------------------------------------------------------
# config
USER="amnesia"
START_DIR="/home/${USER}/Persistent"
INSTALL_DIR="${START_DIR}/Seedsigner"

#------------------------------------------------------
# bash colors
Y="\033[1;33m"    # is Yellow's ANSI color code
G="\033[0;32m"    # is Green's ANSI color code
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
### Check if user really wants to install...or exit
#
echo
echo -e "${Y}This script will install SeedSigner-Emulator into the Persistent directory...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Install apt packages python3-pip / python3-venv (if missing)"
echo "- Create Seedsigner main dir in the Persistent directory (all files go here)"
echo "- Create python virtual environment in ${INSTALL_DIR} dir (venv)"
echo "- Clone the SeedSigner repository"
echo "- Clone the SeedSigner-Emulator repository"
echo "- Copy files from SeedSigner-Emulator dir to SeedSigner dir"
echo "- Download python dependencies into venv"
echo "- Create a start script in the Persistent directory to launch the app"
echo "- Create a start icon in the Applications menu to launch the app"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

# clear screen
clear

#-----------------------------------------------------------------

# enter sudo password once and resuse it later when needed
echo
echo -e "${Y}Enter sudo password once and resuse it later when needed...${NC}"
read -r -s -p "Enter password for sudo:" sudoPW
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

# install python-pip, python-venv
echo
echo -e "${Y}Update apt list / Install python3-pip/python3-venv...${NC}"
echo "$sudoPW" | sudo -S apt-get update
echo "$sudoPW" | sudo -S apt-get -y install python3-pip
echo "$sudoPW" | sudo -S apt-get -y install python3-venv
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

# create Seedsigner dir and cd into it
echo
echo -e "${Y}Create Seedsigner dir and cd into it...${NC}"
mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

# create python virtual environment
echo
echo -e "${Y}Create python virtual environment (venv) in ${INSTALL_DIR}...${NC}"
python3 -m venv "${INSTALL_DIR}"/venv
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

# clone seedsigner repository
echo
echo -e "${Y}Clone SeedSigner repository...${NC}"
git clone http://github.com/SeedSigner/seedsigner.git
cd seedsigner/src
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

# clone seedsigner-emulator repository
echo
echo -e "${Y}Clone SeedSigner-Emulator repository...${NC}"
git clone http://github.com/enteropositivo/seedsigner-emulator.git
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

# copy over needed files from the seedsigner-emulator dir into the seedsigner dir
echo
echo -e "${Y}Copy over needed files from the seedsigner-emulator dir into the seedsigner dir...${NC}"
rsync -a seedsigner-emulator/seedsigner ./
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

# install additional paython packages/dependencies into venv
echo
echo -e "${Y}Install additional paython packages/dependencies into venv...${NC}"
torsocks "${INSTALL_DIR}"/venv/bin/pip3 install --upgrade Pillow
torsocks "${INSTALL_DIR}"/venv/bin/pip3 install --upgrade setuptools
echo "$sudoPW" | sudo -S apt-get -y install python3-tk
echo "$sudoPW" | sudo -S apt-get -y install libzbar0
torsocks "${INSTALL_DIR}"/venv/bin/pip3 install git+https://github.com/jreesun/urtypes.git@e0d0db277ec2339650343eaf7b220fffb9233241
torsocks "${INSTALL_DIR}"/venv/bin/pip3 install git+https://github.com/enteropositivo/pyzbar.git@a52ff0b2e8ff714ba53bbf6461c89d672a304411#egg=pyzbar
torsocks "${INSTALL_DIR}"/venv/bin/pip3 install --upgrade embit dataclasses qrcode tk opencv-python
torsocks "${INSTALL_DIR}"/venv/bin/pip3 install --upgrade zbarcam
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

# cd back into start dir, create start script and make it executable
echo
echo -e "${Y}cd back into ${START_DIR}, create start script and make it executable...${NC}"
cd "${START_DIR}"
cat > "start_seedsigner_emu.sh"<< EOF
#!/bin/bash

cd "${INSTALL_DIR}"/seedsigner/src
"${INSTALL_DIR}"/venv/bin/python3 main.py
EOF
chmod +x start_seedsigner_emu.sh
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

# create dotfiles dirs for the persistent application icon (if not already there)
echo
echo -e "${Y}Create dotfiles dirs for the persistent application icon (if not already there)...${NC}"
echo "$sudoPW" | sudo -S mkdir -p /live/persistence/TailsData_unlocked/dotfiles/.local/share/applications
echo -e "${G}Done.${NC}"

# create .desktop app file for the SeedSigner Emulator (to be able to start via application menu)
echo
echo -e "${Y}Create .desktop app file for the SeedSigner Emulator (to start via application menu)...${NC}"
cat > "desktop"<< EOF
[Desktop Entry]
Name=SeedSigner-Emulator
Comment=SeedSigner-Emulator
Exec=/home/${USER}/Persistent/start_seedsigner_emu.sh
Icon=/home/${USER}/Persistent/Seedsigner/seedsigner/src/seedsigner/resources/img/logo_black_240.png
Terminal=false
Type=Application
Categories=Unknown
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Copy/move the .desktop file to .local/share/applications dir in dotfiles and home dir...${NC}"
# cp the desktop file into the dotfiles dir (to persist the app icon in the Applications menu)
echo "$sudoPW" | sudo -S mv desktop /live/persistence/TailsData_unlocked/dotfiles/.local/share/applications/SeedSigner_Emulator.desktop

# move to amnesia's applications dir to see the app icon immediately
echo "$sudoPW" | sudo -S cp /live/persistence/TailsData_unlocked/dotfiles/.local/share/applications/SeedSigner_Emulator.desktop /home/${USER}/.local/share/applications/
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Installation all done!${NC}"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${START_DIR} + - Tails Persistent dir (contains emulator app / start script)\n" \
        "${INSTALL_DIR} + - Seedsigner-Emulator main installation dir\n" \
        "+\n" \
        "${START_DIR}/start_seedsigner_emu.sh + - Start script to launch the emulator" | column -t -s "+"
echo
echo -e "${LB}You can now start the SeedSigner-Emulator app via:${NC}"
echo " 1. (if you want to see the console in the terminal)"
echo "  cd /home/${USER}/Persistent"
echo "  ./start_seedsigner_emu.sh"
echo " 2. (just the gui)"
echo "  via the icon in the Applications menu (which then starts the start script)"
echo

