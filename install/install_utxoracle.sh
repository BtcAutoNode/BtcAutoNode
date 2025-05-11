#!/bin/bash

#
### download, install UTXOracle (decentralized alternative to knowing the price of btc)
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
echo -e "${Y}This script will download, and install UTXOracle...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Upgrade system to newest software (apt-get update / apt-get upgrade)"
echo "- Create UTXOracle base dir in users home dir (${UTXORACLE_DIR})"
echo "- Download UTXOracle script file from developer's page', version ${UTXORACLE_VERSION}"
echo "- Modify UTXOracle script (to also save to index.html)"
echo "- Create SSL certificates in ${UTXORACLE_DIR}"
echo "- Write UTXOracle httpd server file (to access via browser))"
echo "- Write systemd ${UTXORACLE_SERVICE} service file"
echo "- Change permissions for UTXOracle base dir (${UTXORACLE_DIR}) for user ${USER}"
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
### create UTXOracle base dir
#
echo
echo -e "${Y}Create UTXOracle base (UTXOracle) in ${HOME_DIR}...${NC}"
mkdir -p "${UTXORACLE_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### download UTXOracle script file
#
echo
echo -e "${Y}Download UTXOracle script file into base dir...${NC}"
cd "${UTXORACLE_DIR}"
wget -O UTXOracle.py https://utxo.live/oracle/UTXOracle.py
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### modify UTXOracle script file (filename --> index.html)
#
echo
echo -e "${Y}Modify UTXOracle script (to also save to index.html)...${NC}"
# comment out webbrowser.open line
sed -i "s/^webbrowser.open/#webbrowser.open/g" "$UTXORACLE_DIR/$UTXORACLE_SCRIPT_FILE"
# add line to store html content also into index.html after before line (so the python httpd server shows the file and not the directory content)
sed -i "/#webbrowser/a with open(\"index.html\", \"w\") as f: f.write(html_content)" "$UTXORACLE_DIR/$UTXORACLE_SCRIPT_FILE"
echo -e "${G}Done.${NC}"


#-----------------------------------------------------------------

#
### create ssl certs
#
echo
echo -e "${Y}Create SSL certificates into the UTXOracle dir...${NC}"
# cd into user's UTXOracle dir
cd "${UTXORACLE_DIR}"
# create ssl keys for use in UTXOracle
openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout key.pem -out cert.pem -subj "/C=/ST=/L=/O=/OU=/CN=localhost"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create UTXOracle httpd server file
#
echo
echo -e "${Y}Create UTXOracle httpd server file to start via service...${NC}"
cat > "${UTXORACLE_SERVER_FILE}"<< EOF
#
# Executes the UTXOracle script
# Then starts a webserver to show the created index.html file output
#
port="${UTXORACLE_SSL_PORT}"

# execute UTXOracle script
import subprocess
subprocess.check_call(["python3", "./${UTXORACLE_SCRIPT_FILE}"])

# get local ip
import socket
ip = socket.gethostbyname(socket.gethostname())

# create httpd server
from http.server import HTTPServer, SimpleHTTPRequestHandler
httpd = HTTPServer(("0.0.0.0", int(port)), SimpleHTTPRequestHandler)
# ssl
import ssl
httpd.socket = ssl.wrap_socket (httpd.socket, keyfile="./key.pem", certfile='./cert.pem', server_side=True)

print("Serving HTTPS on 0.0.0.0 port " + port + " (https://" + ip + ":" + port + ") ...", flush=True)
httpd.serve_forever()

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create UTXOracle service file and enter content into the service file
#
echo
echo -e "${Y}Create UTXOracle systemd service file...${NC}"
cat > "${UTXORACLE_SERVICE_FILE}"<< EOF
#
# UTXOracle systemd service file
# Homepage: https://utxo.live/oracle/explain.php                                                             
#
[Unit]
Description=Job to run a python SimpleHTTPServer for the html output of UTXOracle app
After=network.target

[Service]
Type=idle
Restart=on-failure
User=${USER}
Group=${USER}
WorkingDirectory=${UTXORACLE_DIR}
ExecStart=/bin/bash -c '/usr/bin/python3 ${UTXORACLE_SERVER_FILE}'
ExecStop=/bin/kill \`/bin/ps aux | /bin/grep ${UTXORACLE_SERVER_FILE} | /bin/grep -v grep | /usr/bin/awk '{ print $2 }'\`

[Install]
WantedBy=multi-user.target

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### chown UTXOracle dir for user satoshi
#
echo
echo -e "${Y}Change permissions for base dir for user ${USER}...${NC}"
chown -R "${USER}":"${USER}" "${UTXORACLE_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Installation all done!${NC}"
echo
echo -e "${LB}Systemd Service (as root or with sudo as user):${NC}"
echo -e " systemctl enable ${UTXORACLE_SERVICE} + - enable UTXOracle service after boot\n" \
       "systemctl start ${UTXORACLE_SERVICE} + - start UTXOracle service\n" \
       "systemctl stop ${UTXORACLE_SERVICE} + - stop UTXOracle service\n" \
       "systemctl status ${UTXORACLE_SERVICE} + - show UTXOracle service status" | column -t -s "+"
echo
echo -e "${LB}View Log:${NC}"
echo " journalctl -fu ${UTXORACLE_SERVICE}"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${UTXORACLE_DIR} + - UTXOracle base dir (contains scripts, certs, html output)\n" \
      "${UTXORACLE_SCRIPT_FILE} + - UTXOracle script file (from https://utxo.live/oracle/source.php)\n" \
      "${UTXORACLE_SERVER_FILE} + - UTXOracle http server file (for executing the script and starting the python web server)\n" \
      "+\n" \
      "/etc/systemd/system/${UTXORACLE_SERVICE} + - UTXOracle systemd service file" | column -t -s "+"
echo
echo
echo -e "${LB}Open the UTXOracle html output in your browser via the following URL: ${NC}"
echo " https://${LOCAL_IP}:${UTXORACLE_SSL_PORT}"
echo -e "${LB} (It contains yesterday's local node data at the top and a live stream video of the actual data below (from UTXOracle's YT channel)).${NC}"
echo
echo -e "${LB}Starting the service executes the UTXOracle script and opens an http server so output html page can be viewed in the browser.${NC}"
echo
echo -e "${LB}To get new local data the next day, the script needs to be executed again, via:${NC}"
echo -e "${LB}  ${NC}python3 ${UTXORACLE_SCRIPT_FILE}${LB} in ${NC}${UTXORACLE_DIR} ${LB}or${NC}"
echo -e "${LB}  Restarting the service with: ${NC}systemctl restart ${UTXORACLE_SERVICE} ${LB}(which also excutes the script)${NC}"
echo
echo -e "${LB}See more info about what UTXOracle is here: ${NC}https://utxo.live/oracle/explain.php"
echo
