#!/bin/bash

#
### prepare system / install dependencies / create user etc...
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
echo -e "${Y}This script will update and prepare the system for the node installation...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Upgrade system to newest software (apt-get update / apt-get upgrade)"
echo "- Install missing dependencies via apt-get. The following packages are going to be installed:"
echo -e "  - ${LP}${INSTALL_PKGS}${NC}"
echo "- Install newest NodeJS and NPM (version ${NODEJS_VERSION}+)"
echo "- Configure correct timezone (by user interaction)"
echo "- Create user ${USER} as the working user for the apps"
echo "- Set password for user ${USER} (by user interaction)"
echo "- Change .bashrc file for user ${USER} (aliases, prompt,...)"
echo "- Create .ssh dir for ${USER} in ${HOME_DIR}/ and create .ssh/authorized_keys file"
echo "- Allow ssh login via public key and restart of ssh daemon"
echo "- Create .ssh dir for root in /root/ and create .ssh/authorized_keys file"
echo "- Change .bashrc file for root (aliases, prompt,...)"
echo "- Allow ${USER} to execute systemctl command without entering pw"
echo "- Create Nginx config ${NGINX_CONF_FILE}"
echo "- Delete Nginx default site in /etc/nginx/sites-enabled/default"
echo "- Create SSL certificates for nginx"
echo "- Check configs and restart Nginx"
echo "- Install tor from tor repositories (for newest version)"
echo "- Add user ${USER} to tor group"
echo "- Configure tor in ${TORRC_CONF_FILE} file and restart tor"
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
for i in ${INSTALL_PKGS}; do
  echo -e "${LB}Installing package ${i} ...${NC}"
  apt-get -q install -y "${i}"
  echo -e "${LB}Done.${NC}"
done
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### install newest nodejs/npm version
### NodeJS/npm installation: https://github.com/nodesource/distributions#installation-instructions
#
echo
echo -e "${Y}Installing NodeJS/npm from their repository...${NC}"
echo -e "${LB}Creating /etc/apt/keyrings...${NC}"
mkdir -p ${KEYRINGS_DIR}
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o "${NODEJS_KEYRING_FILE}"
NODE_MAJOR="${NODEJS_VERSION}"
echo -e "${LB}Add nodejs repository to ${NODEJS_LIST_FILE}...${NC}"
echo "deb [signed-by=${NODEJS_KEYRING_FILE}] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee "${NODEJS_LIST_FILE}"
echo -e "${LB}Update apt and install...${NC}"
apt-get -q update
apt-get -q --reinstall install nodejs -y
# update npm (based on warning message)
npm install -g npm@10.2.5
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### configure the right timezone (by user interaction)
#
echo
echo -e "${Y}Configuring timezone...${NC}"
echo -e "${LR}Please select the right area and city for your location in the opening application. Press ${NC}<enter>${LR} key to continue...${NC}"
read -r
dpkg-reconfigure tzdata
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### quietly add user satoshi without password
#
echo
echo -e "${Y}Create user ${USER}...${NC}"
id -u "${USER}" &>/dev/null || adduser --quiet --disabled-password --shell /bin/bash --home /home/"${USER}" --gecos "User" "${USER}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### set password for the user (by user input)
#
echo
echo -e "${Y}Set a password for user ${USER}...${NC}"
echo -e "${LR}Please enter a password for the user ${NC}${USER}${LR} and press the ${NC}<enter>${LR} key...${NC}"
read -r USER_PASSWORD
# set/change
echo "satoshi:${USER_PASSWORD}" | chpasswd
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### request user to note down user password
#
echo
echo -e "${LR}Note down the user password just entered!! Press ${NC}<enter>${LR} key to go on:${NC}"
read -r

#-----------------------------------------------------------------

#
### change .bashrc file for user satoshi (append stuff at the end)
#
echo
echo -e "${Y}Add content to .bashrc file for user ${USER}...${NC}"
cat >> "${HOME_DIR}/.bashrc"<< EOF


# list alias
alias l='ls -alF --color'

# Home dir
set home dir
if [ -z "${HOME:-}" ]; then
  export HOME="$(cd ~ && pwd)";
fi

#Prompt (user):
PS1='\[\033[01;36m\]\u\[\033[01;33m\]@\[\033[01;36m\]\h \[\033[01;33m\][\w] \[\033[01;35m\]\$ \[\033[00m\]'

# Hostname Message
toilet -f smblock -f future --filter border:gay '${HOSTNAME}'
cd ~
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create .ssh dir for satoshi and create authorized_keys file
#
echo
echo -e "${Y}Creating .ssh dir for ${USER} and create authorized_keys file...${NC}"
# Create the .ssh directory
echo -e "${LB}Creating ${HOME_DIR}/.ssh dir...${NC}"
mkdir -p "${HOME_DIR}"/.ssh
echo -e "${LB}Creating authorized_keys file in ${HOME_DIR}/.ssh...${NC}"
# Create the authorized keys file
touch "${HOME_DIR}"/.ssh/authorized_keys
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### allow user satoshi to execute systemctl command without entering pw
#
echo
echo -e "${Y}Allow user ${USER} to use systemctl cmd without password...${NC}"
echo "${USER} ALL=(ALL) NOPASSWD: /usr/bin/systemctl" | EDITOR='tee -a' visudo
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create download dir for user satoshi
#
echo
echo -e "${Y}Create downloads directory for user satoshi...${NC}"
if [ ! -d "${DOWNLOAD_DIR}" ]; then
  mkdir -p "${DOWNLOAD_DIR}"
fi
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permissions of files/directories for user satoshi
#
echo
echo -e "${Y}Change permissions of files/directories for users ${USER}...${NC}"
# download dir
chown -R "${USER}":"${USER}" "${DOWNLOAD_DIR}"
# .ssh dir
chown -R "${USER}":"${USER}" "${HOME_DIR}"/.ssh
chmod 0700 "${HOME_DIR}"/.ssh
chown "${USER}":"${USER}" "${HOME_DIR}"/.ssh/authorized_keys
chmod 0600 "${HOME_DIR}"/.ssh/authorized_keys
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### allow ssh login with public key in /etc/ssh/sshd_config
### change config line with sed and restart sshd service
#
echo
echo -e "${Y}Allow ssh login via public key in /etc/ssh/sshd_config...${NC}"
sed -i "s/^#PubkeyAuthentication.*/PubkeyAuthentication yes/g" /etc/ssh/sshd_config
# restart sshd service
echo -e "${LB}Restarting ssh daemon...${NC}"
systemctl restart sshd
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create .ssh dir for root and create authorized_keys file
#
echo
echo -e "${Y}Creating .ssh dir for root user and create authorized_keys file...${NC}"
# Create the .ssh directory, and set its permissions
echo -e "${LB}Creating /root/.ssh dir and change permissions...${NC}"
mkdir -p /root/.ssh
chmod 0700 /root/.ssh
echo -e "${LB}Creating authorized_keys file in /root/.ssh and change permissions...${NC}"
# Create the authorized keys file, and set its permissions
touch /root/.ssh/authorized_keys
chmod 0600 /root/.ssh/authorized_keys
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change .bashrc file for root (append stuff at the end)
#
echo
echo -e "${Y}Add content to .bashrc file for root...${NC}"
cat > "/root/.bashrc"<< EOF
# list alias
alias l='ls -alF --color'
alias upd='apt-get update && apt-get upgrade -y'

# Home dir
set home dir
if [ -z "${HOME:-}" ]; then
  export HOME="$(cd ~ && pwd)";
fi

# Prompt(root):
PS1='\[\033[01;31m\]\u\[\033[01;33m\]@\[\033[01;36m\]\h \[\033[01;33m\][\w] \[\033[01;35m\]\$ \[\033[00m\]'

# Hostname Message
toilet -f smblock -f future --filter border:gay '${HOSTNAME}'
cd ~
EOF
echo -e "${LB}Enter: 'source .bashrc' (to reload after script is finished)${NC}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### nginx main config
#
echo
echo -e "${Y}Write Nginx main config file...${NC}"
mv "${NGINX_CONF_FILE}" "${NGINX_CONF_FILE}.bak"
cat > "${NGINX_CONF_FILE}"<< EOF
# nginx main conf

user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
        worker_connections 768;
}

http {
        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;
        keepalive_timeout 65;
        types_hash_max_size 2048;
        server_tokens off;
        include /etc/nginx/mime.types;
        default_type application/octet-stream;
        ssl_protocols TLSv1.3;
        ssl_prefer_server_ciphers on;
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;
        gzip on;
        include /etc/nginx/conf.d/*.conf;
        include /etc/nginx/sites-enabled/*;
}

stream {
        ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
        ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
        ssl_session_cache shared:SSL:1m;
        ssl_session_timeout 4h;
        ssl_protocols TLSv1.3;
        ssl_prefer_server_ciphers on;
        include /etc/nginx/streams-enabled/*.conf;
}
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### delete nginx default site in site-enabled
#
echo
echo -e "${Y}Delete nginx default site in site-enabled...${NC}"
rm -f /etc/nginx/sites-enabled/default
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create ssl certs for nginx
#
echo
echo -e "${Y}Create ssl certificates for use in Nginx...${NC}"
openssl req -x509 -nodes -newkey rsa:4096 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj "/CN=localhost" -days 3650
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create nginx snippets and streams-enabled dirs
#
echo
echo -e "${Y}Create nginx snippets and streams-enabled dirs...${NC}"
mkdir -p "${NGINX_SNIPPETS_DIR}"
mkdir -p "${NGINX_STREAMS_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### check nginx config
#
echo
echo -e "${Y}Checking nginx configs...${NC}"
nginx -t
if [ "$?" -eq 0 ]; then
  echo -e "${G}Nginx configs: OK${NC}"
else
  echo -e "${R}Nginx configs: Not OK${NC}"
  exit
fi
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### restart nginx webserver
#
echo
echo -e "${Y}Restart Nginx web server...${NC}"
systemctl restart nginx
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### Install tor from tor repository (to always have newest version)
#
echo
echo -e "${Y}Install tor from tor repositories (for newest version)...${NC}"
echo -e "${LB}Add tor repository to ${TOR_LIST_FILE}...${NC}"
cat > "${TOR_LIST_FILE}"<< EOF
deb     [arch=${ARCH} signed-by=${TOR_KEYRING_FILE}] https://deb.torproject.org/torproject.org ${RELEASE_CODE} main
deb-src [arch=${ARCH} signed-by=${TOR_KEYRING_FILE}] https://deb.torproject.org/torproject.org ${RELEASE_CODE} main
EOF
# get gpg key
wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | tee "${TOR_KEYRING_FILE}" >/dev/null
# install tor and tor debian keyring
echo -e "${LB}Update apt and install...${NC}"
apt-get -q update
apt-get -q install tor deb.torproject.org-keyring -y
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### Add user satoshi to tor group
#
echo
echo -e "${Y}Add user ${USER} to tor group...${NC}"
usermod -a -G debian-tor "${USER}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### Tor
#
# configure tor
echo
echo -e "${Y}Edit /etc/tor/torrc config...${NC}"
# append tor config at end of torrc config file
#{ echo "ControlPort 9051"; \
#  echo "CookieAuthentication 1"; \
#  echo "CookieAuthFileGroupReadable 1"; \
#  echo "SocksPort localhost:9050";} >> "${TORRC_CONF_FILE}"
grep -qxF 'ControlPort 9051' "${TORRC_CONF_FILE}" || echo 'ControlPort 9051' >> "${TORRC_CONF_FILE}"
grep -qxF 'CookieAuthentication 1' "${TORRC_CONF_FILE}" || echo 'CookieAuthentication 1' >> "${TORRC_CONF_FILE}"
grep -qxF 'CookieAuthFileGroupReadable 1' "${TORRC_CONF_FILE}" || echo 'CookieAuthFileGroupReadable 1' >> "${TORRC_CONF_FILE}"
grep -qxF 'SocksPort localhost:9050' "${TORRC_CONF_FILE}" || echo 'SocksPort localhost:9050' >> "${TORRC_CONF_FILE}"
# restart tor
echo -e "${Y}Restarting tor service...${NC}"
systemctl restart tor
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

echo
echo -e "${Y}Installation all done!${NC}"
echo
echo -e "${LB}User for the applications:${NC}"
echo -e " User: + ${USER}\n" \
        "User home dir: + ${HOME_DIR}\n" \
        "User download dir: + ${DOWNLOAD_DIR}\n" \
        "+" | column -t -s "+"
echo
echo -e " ${LB}Files and Directories:${NC}"
echo -e " ${TORRC_CONF_FILE} + - Tor torrc config file\n" \
        "${TORSOCKS_CONF_FILE} + - Tor socks proxy config file\n" \
        "${TOR_LIST_FILE} + - file for Tor deb archive links\n" \
        "${TOR_KEYRING_FILE} + - Tor gpg keyring file\n" \
        "+\n" \
        "${NODEJS_LIST_FILE} + - file for Nodejs deb archive links\n" \
        "${NODEJS_KEYRING_FILE} + - Nodejs gpg keyring file\n" \
        "+\n" \
        "${NGINX_CONF_FILE} + - Nginx web server config file\n" \
        "${NGINX_WEBROOT_DIR} + - Nginx web root dir\n" \
        "+\n" \
        "${HOME_DIR}/.ssh + - ssh dir for user ${USER} (authorized_keys file)\n" \
        "/root/.ssh + - ssh dir for user root (authorized_keys file)" | column -t -s "+"
echo
echo -e "${LB}Enter 'source ~/.bashrc' to reload the changed root profile.${NC}"
echo -e "${LB}You can then use 'l' for dir listings in color'.${NC}"
echo
echo -e "${LB}IP address of the machine: ${LOCAL_IP}${NC}"
echo
echo -e "${LB}For security reasons you should connect to the server via ssh keys.${NC}"
echo -e "${LB}See the chapter 'Login with SSH keys' for instructions:${NC}"
echo " https://raspibolt.org/guide/raspberry-pi/security.html#login-with-ssh-keys"
echo
