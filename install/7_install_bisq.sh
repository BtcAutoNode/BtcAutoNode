#!/bin/bash

#
### download, verify, install Bisq (in headless mode)
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
source CONFIG

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
echo -e "${Y}This script will download, verify and install Bisq (headless)...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Upgrade system to newest software (apt-get update / apt-get upgrade)"
echo "- Add xpra repository and install xpra via apt"
echo "- Install Java, version ${BISQ_JAVA_VERSION}"
echo "- Create Bisq download dir (${BISQ_DOWNLOAD_DIR})"
echo "- Download the release, verify, extract and move to ${BISQ_APP_DIR} dir"
echo "- Change permissions of ${BISQ_APP_DIR} dir for user ${USER}"
echo "- Build Bisq application"
echo "- Create SSL certs for xpra (place into ${BISQ_APP_DIR} dir)"
echo "- Query for xpra session password (by user interaction)"
echo "- Create start/stop scripts for Bisq xpra"
echo "- Change permissions of file for user ${USER}"
echo "- Disable and stop avahi daemon"
echo "- Kill running jvm processes / stop Bisq gradle server(s)"
#echo "- Allow Inbound connections in ${TORSOCKS_CONF} file"
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
### add xpra repository to new /etc/apt/sources.list.d/xpra_bisq.list file
#
echo
echo -e "${Y}aAdd new XPRA repository to apt configs${NC}"
echo -e "${LB}Create new repository file in /etc/apt/sources.list.d - xpra_bisq.list${NC}"
touch "${BISQ_LIST_FILE}"
echo "deb https://xpra.org/ ${RELEASE_CODE} main" > "${BISQ_LIST_FILE}"
echo -e "${LB}Download and add new repositor gpg key${NC}"
wget -q https://xpra.org/gpg.asc -O- | apt-key add -
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### refresh repositories
#
echo
echo -e "${Y}Updating system via apt with new xpra repository...${NC}"
apt-get update
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### install XPRA
#
echo
echo -e "${Y}Install XPRA...${NC}"
apt-get install xpra -y
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### verify xpra version (to see that it is installed)
#
echo
echo -e "${Y}Check XPRA version to check that installation worked...${NC}"
xpra --version
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### install java
#
echo
echo -e "${Y}Install java ${BISQ_JAVA_VERSION} via apt...${NC}"
#apt-get install default-jre default-jdk -y
apt-get install openjdk-"${BISQ_JAVA_VERSION}"-jre openjdk-"${BISQ_JAVA_VERSION}"-jdk -y
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create Bisq download dir
#
echo
echo -e "${Y}Create downloads directory ${BISQ_DOWNLOAD_DIR} for user ${USER}...${NC}"
mkdir -p "${BISQ_DOWNLOAD_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### download and overwrite bisq source code release, build and install Bisq
#
echo
echo -e "${Y}Download and overwrite Bisq github source code release...${NC}"
cd "${BISQ_DOWNLOAD_DIR}"
wget -O bisq-"${BISQ_VERSION}".tar.gz https://github.com/bisq-network/bisq/archive/refs/tags/v"${BISQ_VERSION}".tar.gz
wget -O bisq-"${BISQ_VERSION}".tar.gz.asc https://github.com/bisq-network/bisq/releases/download/v"${BISQ_VERSION}"/bisq-"${BISQ_VERSION}".tar.gz.asc
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### verify the release
#
echo
echo -e "${Y}Verify the release files...${NC}"
# download gpg key
wget -O E222AA02.asc https://bisq.network/pubkey/E222AA02.asc
# import into gpg
gpg --import -q E222AA02.asc || true
# verify
gpg --digest-algo SHA256 --verify bisq-"${BISQ_VERSION}".tar.gz{.asc*,} 2>&1 >/dev/null | grep 'Good signature'
if [ "$?" = !0 ]; then
  echo -e "${R}The signature(s) for the downloaded file are not good signature. Exiting now.${NC}"
  exit 1
else
  echo -e "${G}The signature(s) for the downloaded file are good signature(s).${NC}"
fi
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### extract bisq release
#
echo
echo -e "${Y}Extract Bisq release...${NC}"
# extract
tar xvfz bisq-"${BISQ_VERSION}".tar.gz
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### move bisq to satoshi home dir
#
echo
echo -e "${Y}Move extracted Bisq dir to ${USER} home dir...${NC}"
mv bisq-"${BISQ_VERSION}"/ "${BISQ_APP_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permission of folders for user ${USER}
#
echo
echo -e "${Y}Change permissions of folders for user ${USER}...${NC}"
chown -R "${USER}":"${USER}" "${BISQ_DOWNLOAD_DIR}"
chown -R "${USER}":"${USER}" "${BISQ_APP_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### build Bisq from sources (as user satoshi)
### (build without core:test as this always failed)
#
echo
echo -e "${Y}Build Bisq from repository sources (as user ${USER})...${NC}"
echo -e "${LB}This can take quite some time!${NC}"
# change gradle version (otherwise the build fails building the 1st time (2nd works then))
sed -i "s/7.6/7.6.3/g" "${BISQ_APP_DIR}"/gradle/wrapper/gradle-wrapper.properties
# change into bisq dir and build (exclude core:test as a few tests always fail)
cd "${BISQ_APP_DIR}"
su -c './gradlew clean build --no-daemon -x core:test' "${USER}"
# remove cache files
su -c 'rm -rf ${HOME_DIR}/.gradle/caches' "${USER}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create ssl certificate for xpra
#
echo
echo -e "${Y}Create SSL certificate for xpra...${NC}"
cd "${BISQ_APP_DIR}"
openssl req -new -x509 -nodes -out cert.pem -keyout cert.pem -subj "/C=/ST=/L=/O=/OU=/CN=localhost"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### ask user to enter a password for xpra session
#
echo
echo -e "${Y}Passwort for the bisq start script...${NC}"
echo -e "${LR}Please enter a ${NC}password${LR} to access the xpra session in the browser later and press the ${NC}<enter>${LR} key...${NC}"
read -r XPRA_PASSWORD
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create start / stop scripts for user satoshi
#
echo
echo -e "${Y}Create start/stop scripts for user ${USER}...${NC}"
cat > "${BISQ_START_SCRIPT}"<< EOF
# xpra bisq start script

xpra start :100 --mdns=no --bind-tcp=0.0.0.0:9876 --tcp-auth=password:value=${XPRA_PASSWORD} --ssl=on --ssl-cert="${BISQ_APP_DIR}/cert.pem" --html=on \
--start="${BISQ_APP_DIR}/bisq-desktop \
--appData=${BISQ_DATA_DIR}" --no-pulseaudio --no-speaker --terminate-children=yes

echo
echo
echo "After start the bisq application can be seen in the webbrowser with the following URL:"
echo "https://$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'):9876"
echo "Enter password provided in the installation (--> ${XPRA_PASSWORD}) and wait until Bisq starts (which can take a few minutes)."
echo "(Only password needed, no username.)"
echo
echo "When finished in Bisq, just close the browser window...the application is still running in the background."
echo "Just again open in the browser if you want to access Bisq again."
echo
echo "To really stop the Bisq app, go to the browser session and first close the application from there (X in right upper corner)."
echo "When closed, then use the bisq stop script ( ./bisq_stop_xpra.sh ) and wait until it's finished before you logout."
echo
echo
EOF

cat > "${BISQ_STOP_SCRIPT}"<< EOF
xpra stop :100 # to stop the running xpra instance
xpra stop :100 # once more, to REALLY stop the running xpra instance (sometimes it won't work with just one call, especially when restarting Bisq)

# kill java process
javapid=\$(ps aux | grep ${USER} | pgrep -f bisq/gradle)
echo "java-pid: \${javapid}"
kill -SIGTERM "\${javapid}"

# kill jvm process
jvmpid=\$(ps aux | grep ${USER} | pgrep -f jvm)
echo "jvm-pid: \${jvmpid}"
kill -SIGTERM "\${jvmpid}"
EOF
# execute permission for start/stop scripts
chmod +x "${BISQ_START_SCRIPT}"
chmod +x "${BISQ_STOP_SCRIPT}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permission of files for user ${USER}
#
echo
echo -e "${Y}Change permissions of files for user ${USER}...${NC}"
chown "${USER}":"${USER}" "${BISQ_START_SCRIPT}"
chown "${USER}":"${USER}" "${BISQ_STOP_SCRIPT}"
chown "${USER}":"${USER}" "${BISQ_APP_DIR}/cert.pem"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### add user satoshi to group lpadmin
#
echo
echo -e "${Y}Add user ${USER} to group lpadmin...${NC}"
usermod -a -G lpadmin "${USER}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### disable and stop avahi-daemon
#
#echo
#echo -e "${Y}Disable and stop avahi-daemon...${NC}"
#systemctl disable avahi-daemon
#systemctl stop avahi-daemon
#echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### kill some jvm processes if still running
#
#echo
#echo -e "${Y}Kill some jvm processes if still running...${NC}"
#for pid in $(ps -ef | grep "jvm" | awk '{print $2}'); do kill -9 $pid; done
#echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### stop bisq gradle server(s) running
#
#echo
#echo -e "${Y}Stop bisq xpra server...${NC}"
#gradle --stop
#echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# allow Inbound connections in /etc/tor/torsocks file
#
#echo
#echo -e "${Y}Allow Inbound connections in ${TORSOCKS_CONF} file...${NC}"
#sed -i "s/^#AllowInbound.*/AllowInbound 1/g" "${TORSOCKS_CONF}"
#echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Installation all done!${NC}"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${BISQ_DOWNLOAD_DIR} + - Bisq download directory\n" \
        "${BISQ_APP_DIR} + - Bisq application dir\n" \
        "${BISQ_DATA_DIR} + - Bisq data dir\n" \
        "+\n" \
        "${BISQ_START_SCRIPT} + - Bisq xpra start script\n" \
        "${BISQ_STOP_SCRIPT} + - Bisq xpra stop script\n" \
        "${BISQ_LIST_FILE} + - file for Xpra deb archive links\n" \
        "${TORSOCKS_CONF} + - tor proxy config file" | column -t -s "+"
echo
echo -e "${LB}Use the start script ( ${NC}./start_bisq_xpra.sh${LB} ) to start Bisq in a xpra session... ${NC}"
echo -e "${LB} which can be accessed via a web browser (start script shows URL and passwd).${NC}"
echo
echo -e "${LB}After first start the Bisq data dir ${NC}${BISQ_DATA_DIR}${LB} is created.${NC}"
echo -e "${LB}The content of the data dir of a graphical/Desktop Bisq app can be placed here.${NC}"
echo -e "${LB}(Make sure that it already points to the new node (network settings in Bisq)).${NC}"
echo
echo -e "${LB}Here are more information on how to find it:${NC}"
echo " https://bisq.wiki/Data_directory"
echo

