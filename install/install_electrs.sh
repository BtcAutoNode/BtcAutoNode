#!/bin/bash

#
### download, verify, install Electrs (Electrum Server in Rust)
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
echo -e "${Y}This script will download, verify and install the Electrs Electrum Server...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Upgrade system to newest software (apt-get update / apt-get upgrade)"
echo "- Install missing dependencies via apt (${ELECTRS_PKGS})"
echo "- Clone Electrs Github repository, version ${ELECTRS_VERSION}"
echo "- Create Electrs config file (${ELECTRS_CONF_FILE})"
echo "- Build the Electrs application"
echo "- Install the Electrs binaries into /usr/local/bin"
echo "- Create Electrs data dir (${ELECTRS_DATA_DIR})"
echo "- Change permissions for Electrs base and data dir for user ${USER}"
echo "- Create systemd service file (${ELECTRS_SERVICE_FILE})"
echo "- Create nginx config (${ELECTRS_NGINX_SSL_CONF})"
echo "- Check nginx configs and reload nginx web server"
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
### install dependencies
#
echo
echo -e "${Y}Installing dependencies...${NC}"
for i in ${ELECTRS_PKGS}; do
  echo -e "${LB}Installing package ${i} ...${NC}"
  apt-get -q install -y "${i}"
  echo -e "${LB}Done.${NC}"
done
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### install latest rust
#
echo
echo -e "${Y}Install latest rust...${NC}"
# https://rustup.rs/
wget -O /tmp/rustup.sh https://sh.rustup.rs
chmod +x /tmp/rustup.sh
/tmp/rustup.sh -y
rm /tmp/rustup.sh
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### cd into homedir and download electrs git repository into ${HOME_DIR}
#
echo
echo -e "${Y}Cd into ${HOME_DIR} and clone the Electrs git repository...${NC}"
cd "${HOME_DIR}"
# delete dir if exist
rm -rf "${ELECTRS_DIR}"
git clone https://github.com/romanz/electrs.git
cd "${ELECTRS_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### git checkout at config version
#
echo
echo -e "${Y}Git checkout at config version...${NC}"
latestrelease="v${ELECTRS_VERSION}"
git -c advice.detachedHead=false checkout "${latestrelease}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------
#
### verify the source code
#
echo
echo -e "${Y}Verify the release source code...${NC}"
# download gpg key
wget -O pgp.txt https://romanzey.de/pgp.txt
# import into gpg
gpg --import -q pgp.txt || true
# verify
if ! git verify-tag v"${ELECTRS_VERSION}"; then
  echo -e "${R}The signature(s) for the source code are not good signature. Exiting now.${NC}"
  exit 1
else
  echo -e "${G}The signature(s) for the source code are good signature(s).${NC}"
fi
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create electrs config file ${ELECTRS_CONF_FILE}
#
echo
echo -e "${Y}Write Electrs ${ELECTRS_CONF_FILE} config file...${NC}"
cat > "${ELECTRS_CONF_FILE}"<< EOF
#
# Electrs configuration
# ${HOME_DIR}/electrs/electrs.conf
#

# Bitcoin Core settings
network = "bitcoin"
daemon_dir= "${HOME_DIR}/.bitcoin"
cookie_file = "${HOME_DIR}/.bitcoin/.cookie"
daemon_rpc_addr = "127.0.0.1:8332"
daemon_p2p_addr = "127.0.0.1:8333"

# Electrs settings
electrum_rpc_addr = "127.0.0.1:50001"
db_dir = "${HOME_DIR}/electrs_db"

# Logging
log_filters = "INFO"
timestamp = true
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### build the electrs application
#
echo
echo -e "${Y}Build the Electrs application...${NC}"
echo -e "${LB}This can take quite some time!${NC}"
# add /root/.cargo/bin to PATH
export PATH="$PATH":/root/.cargo/bin
# build
cd "${ELECTRS_DIR}"
cargo build --locked --release
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### install the binaries into /usr/local/bin
#
echo
echo -e "${Y}Install the binaris into /usr/local/bin...${NC}"
sudo install -m 0755 -o root -g root -t /usr/local/bin ./target/release/electrs
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create electrs data dir
#
echo
echo -e "${Y}Create Electrs data dir (electrs_db) in ${HOME_DIR}...${NC}"
mkdir -p "${ELECTRS_DATA_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permissions of the electrs base and data dir for user satoshi
#
echo
echo -e "${Y}Change permissions of ${ELECTRS_DIR} and ${ELECTRS_DATA_DIR} for user ${USER}...${NC}"
chown -R "${USER}":"${USER}" "${ELECTRS_DIR}"
chown -R "${USER}":"${USER}" "${ELECTRS_DATA_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create systemd service file for electrs
#
echo
echo -e "${Y}Create systemd service file for Electrs...${NC}"
cat > "${ELECTRS_SERVICE_FILE}"<< EOF
#
# systemd unit file for electrs
# /etc/systemd/system/electrs.service
# example service file: 
#
[Unit]
Description=Electrs daemon
After=bitcoind.service

[Service]
WorkingDirectory=${HOME_DIR}/electrs
ExecStart=/usr/local/bin/electrs --conf ${HOME_DIR}/electrs/electrs.conf
User=${USER}
Group=${USER}
Type=simple
KillMode=process
TimeoutSec=60
Restart=always
RestartSec=60

Environment="RUST_BACKTRACE=1"

# Hardening measures
PrivateTmp=true
ProtectSystem=full
NoNewPrivileges=true
MemoryDenyWriteExecute=true

[Install]
WantedBy=multi-user.target

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### nginx electrs reverse proxy ssl config
#
echo
echo -e "${Y}Write nginx Electrs reverse proxy ssl config (${ELECTRS_NGINX_SSL_CONF})...${NC}"
cat > "${ELECTRS_NGINX_SSL_CONF}"<< EOF
upstream electrs {
  server 127.0.0.1:50001;
}

server {
  listen 50002 ssl;
  listen [::]:50002 ssl;
  proxy_pass electrs;
}

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### check nginx config
#
echo
echo -e "${Y}Checking nginx configs...${NC}"
if nginx -t; then
  echo -e "${G}Nginx configs: OK${NC}"
else
  echo -e "${R}Nginx configs: Not OK${NC}"
  exit
fi
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### reload nginx webserver
#
echo
echo -e "${Y}Restart Nginx web server...${NC}"
systemctl reload nginx
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### uninstall rust
#
echo
echo -e "${Y}Uninstall rust...${NC}"
# uninstall rust
/root/.cargo/bin/rustup self uninstall -y
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Installation all done!${NC}"
echo
echo -e "${LB}Systemd Service (as root or with sudo as user):${NC}"
echo -e " systemctl enable ${ELECTRS_SERVICE} - enable Electrs service after boot\n" \
        "systemctl start ${ELECTRS_SERVICE}  - start Electrs service\n" \
        "systemctl stop ${ELECTRS_SERVICE}   - stop Electrs service\n" \
        "systemctl status ${ELECTRS_SERVICE} - show Electrs service status" | column -t -s "+"
echo
echo -e "${LB}View Log:${NC}"
echo " journalctl -fu ${ELECTRS_SERVICE}"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${ELECTRS_DIR} + - Electrs base directory\n" \
        "${ELECTRS_DATA_DIR} + - Electrs data dir (contains the indexes)\n" \
        "${ELECTRS_CONF_FILE} + - Electrs config file\n" \
        "+\n" \
        "${ELECTRS_SERVICE_FILE} + - Electrs systemd service file\n" \
        "+\n" \
        "${ELECTRS_NGINX_SSL_CONF} + - Electrs Nginx ssl config" | column -t -s "+"
echo

