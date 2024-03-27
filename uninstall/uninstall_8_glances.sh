#!/bin/bash

#
### check if CONFIG file is there and not empty, otherwise exit
#
if [[ ! -f CONFIG || ! -s CONFIG ]] ; then
    echo '"CONFIG" file is not there or empty, exiting.'
    exit
fi

#-----------------------------------------------------------------

#
# config
#
. CONFIG

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
### Check if user really wants to uninstall...or exit
#
echo
echo -e "${Y}This script will uninstall all files/folders of the Glances installation...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Stop Glances systemd service (${GLANCES_SERVICE})"
echo "- Disable Glances systemd service (${GLANCES_SERVICE})"
echo "- Delete Glances systemd service file (${GLANCES_SERVICE_FILE})"
echo "- Download Glances uninstallation script into /tmp"
echo "- Uninstall Glances via uninstaller script"
echo "- Delete Glances nginx config files (${GLANCES_NGINX_SSL_CONF} + sym-link)"
echo "- Delete different Glances files and folders"
echo "- Restart nginx web server"
echo
echo -e "${LR}Press ${NC}<enter>${LR} key to continue, or ${NC}ctrl-c${LR} to exit${NC}"
read -r

#-----------------------------------------------------------------

#
# stop glances service
#
echo
echo -e "${Y}Stop Glances service (${GLANCES_SERVICE})...${NC}"
systemctl stop "${GLANCES_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# disable glances service
#
echo
echo -e "${Y}Disable Glances service (${GLANCES_SERVICE})...${NC}"
systemctl disable "${GLANCES_SERVICE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete glances service file
#
echo
echo -e "${Y}Delete Glances service file (${GLANCES_SERVICE_FILE})...${NC}"
rm -f "${GLANCES_SERVICE_FILE}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### download Glances uninstallation script
#
echo
echo -e "${Y}Download Glances uninstallation script into /tmp...${NC}"
cd "/tmp" || { echo "cd /tmp failed"; exit 1; }
# glances install script
wget -qO /tmp/uninstall_glances.sh https://raw.githubusercontent.com/nicolargo/glancesautoinstall/master/uninstall.sh
chmod +x /tmp/uninstall_glances.sh
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### uninstallation via uninstall script
#
echo
echo -e "${Y}Uninstall Glances via uninstaller script...${NC}"
# change pip uninstall commands for non-interaction
sed -i 's/pip uninstall/pip uninstall -y/g' /tmp/uninstall_glances.sh
. /tmp/uninstall_glances.sh
# delete uninstall script after uninstallation
rm -f /tmp/uninstall_glances.sh
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete nginx config files
#
echo
echo -e "${Y}Delete Glances nginx files...${NC}"
rm -f "${GLANCES_NGINX_SSL_CONF}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# delete different glances files and folders
#
echo
echo -e "${Y}Delete Glances cache/log folders...${NC}"
# delete folders
rm -rf /root/.cache/glances
rm -rf /root/.local/share/glances
rm -rf "${HOME_DIR}"/.cache/glances
rm -rf "${HOME_DIR}"/.local/share/glances
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# restart nginx
#
echo
echo -e "${Y}Restart Nginx...${NC}"
systemctl restart nginx
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Uninstallation all done!${NC}"
echo

