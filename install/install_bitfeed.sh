#!/bin/bash

#
### download and install Bitfeed (live visualization of Bitcoin network activity)
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
echo -e "${Y}This script will download and install Bitfeed...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Upgrade system to newest software (apt-get update / apt-get upgrade)"
echo "- Install missing dependencies via apt (${BITFEED_PKGS})"
echo "- Clone Bitfeed Github repository, version ${BITFEED_VERSION}"
echo "- Build the Bitfeed backend part (server)"
echo "- Build the Bitfeed frontend part (client)"
echo "- Clean up mix caches from build (/root/.mix .hex .cache/rebar3)"
echo "- Clean up npm caches from build (/root/.cache)"
echo "- Move content of client/public/build directory into ${BITFEED_WEBROOT_DIR}"
echo "- Change permissions of directories for users ${USER}, www-data"
echo "- Create systemd ${BITFEED_SERVICE} service file"
echo "- Create nginx configs, check nginx and restart nginx web server"
echo "- Change permissions for the Bitfeed base dir ${BITFEED_DIR} for user ${USER}"
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
for i in ${BITFEED_PKGS}; do
  echo -e "${LB}Installing package ${i} ...${NC}"
  apt-get -q install -y "${i}"
  echo -e "${LB}Done.${NC}"
done
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### cd into homedir and download bitfeed git repository as user satoshi in /home/satoshi
#
echo
echo -e "${Y}Cd into ${HOME_DIR} and clone Bitfeed git repository...${NC}"
cd "${HOME_DIR}"
# delete dir if exist
rm -rf "${BITFEED_DIR}"
git clone https://github.com/bitfeed-project/bitfeed.git
cd "${BITFEED_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### get the latest release from github and checkout git there
#
echo
echo -e "${Y}Get latest release and git checkout at this release...${NC}"
latestrelease="v${BITFEED_VERSION}"
git -c advice.detachedHead=false checkout "${latestrelease}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

# fix base58 compile error in Debian 12 and Ubuntu 23.04
NAME=$(cat /etc/os-release | grep ^ID= | cut -d '=' -f 2)
VER=$(cat /etc/os-release | grep VERSION_ID | cut -d '=' -f 2)
VER=${VER#\"}               # Remove optional leading "
VER=${VER%\"}               # remove trailing "
#echo $NAME
#echo $VER
if ([ "$NAME" = "debian" ] && [ "$VER" = "12" ]) || ([ "$NAME" = "ubuntu" ] && [ "$VER" = "23.04" ]); then
  #echo "true"
  sed -i.bak -e '125,131d' "${BITFEED_DIR}"/server/bitcoinex/lib/base58.ex
fi
#-----------------------------------------------------------------

#
### build the bitfeed backend part
#
echo
echo -e "${Y}Build the backend part of Bitfeed...${NC}"
echo -e "${LB}This can take several minutes!${NC}"
# install/build
cd "${BITFEED_BACKEND_DIR}"
mix local.rebar --force
mix local.hex --force
mix do deps.get
mix do deps.compile
mix release
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### build the bitfeed frontend part
#
echo
echo -e "${Y}Build the frontend part of Bitfeed...${NC}"
echo -e "${LB}This can take some time!${NC}"
cd "${BITFEED_FRONTEND_DIR}"
# update npm (from warnings)
npm install -g npm@"${NPM_UPD_VER}"
npm install
npm run build
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### clean up mix cache dirs from build
#
echo
echo -e "${Y}Clean mix caches from build...${NC}"
rm -rf /root/.mix
rm -rf /root/.hex
rm -rf /root/.cache/rebar3
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### clean up npm caches from build
#
echo
echo -e "${Y}Clean npm caches from build...${NC}"
# clean the npm cache and delete npm cache dir
npm cache clean --force
rm -rf "$(npm get cache)"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### Move the content of the client/public/build directory into /var/www/html/ directory (web root)
#
echo
echo -e "${Y}Move client/public/build dir into the web root dir...${NC}"
rm -rf "${BITFEED_WEBROOT_DIR}"
mv "${BITFEED_FRONTEND_DIR}"/public/build "${BITFEED_WEBROOT_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permission of bitfeed web root dir to www-data
#
echo
echo -e "${Y}Change permission of Bitfeed web dir ${BITFEED_WEBROOT_DIR} for user www-data...${NC}"
chown -R www-data:www-data "${BITFEED_WEBROOT_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permissions of the /home/satoshi/bitfeed dir to user satoshi
#
echo
echo -e "${Y}Change permissions of ${BITFEED_DIR} to user ${USER}...${NC}"
chown -R "${USER}":"${USER}" "${BITFEED_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create systemd service for for bitfeed
#
echo
echo -e "${Y}Create systemd service file for Bitfeed (${BITFEED_SERVICE_FILE})...${NC}"
cat > "${BITFEED_SERVICE_FILE}"<< EOF

[Unit]
Description=Bitcoin event streaming server
After=network.target
Requires=network.target

[Service]
Type=simple
User=${USER}
Group=${USER}
Restart=on-failure

# Environment vars for bitfeed
Environment=MIX_ENV=prod
Environment=Target=personal
Environment=RELEASE_NODE=bitfeed
Environment=LANG=en_US.UTF-8
Environment=PORT=9999
Environment=BITCOIN_RPC_COOKIE=${BITCOIN_DIR}/.cookie
Environment=BITCOIN_HOST=127.0.0.1
Environment=BITCOIN_RPC_PORT=8332
Environment=BITCOIN_ZMQ_RAWBLOCK_PORT=28332
Environment=BITCOIN_ZMQ_RAWTX_PORT=28333
Environment=BITCOIN_ZMQ_SEQUENCE_PORT=28335

WorkingDirectory=${BITFEED_BACKEND_DIR}

# start/stop commands
ExecStart=/bin/bash ${BITFEED_BACKEND_DIR}/_build/dev/rel/prod/bin/prod start
ExecStop=/bin/bash ${BITFEED_BACKEND_DIR}/_build/dev/rel/prod/bin/prod stop

[Install]
WantedBy=multi-user.target

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### nginx bitfeed ssl config
#
echo
echo -e "${Y}Write nginx Bitfeed ssl config file (${BITFEED_NGINX_SSL_CONF})...${NC}"
cat > "${BITFEED_NGINX_SSL_CONF}"<< EOF
# bitfeed ssl conf, put into sites-availabe

map \$sent_http_content_type \$expires {
    default                 off;
    text/css                max;
    text/json               max;
    application/javascript  max;
}

add_header Cache-Control 'no-cache';


upstream wsmonobackend {
    server 127.0.0.1:9999;
}

server {
    listen ${BITFEED_SSL_PORT} ssl;
    listen [::]:${BITFEED_SSL_PORT} ssl;
    server_name _;

    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
    ssl_session_timeout 4h;
    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers on;

    root /var/www/html/bitfeed;
    index index.html;

    server_name client;

    location ~* \.(html)$ {
            add_header Cache-Control 'no-cache';
    }

    location /api {
            proxy_pass http://wsmonobackend;
            proxy_set_header        Host \$http_host;
            proxy_set_header        X-Real-IP \$remote_addr;
    }

    location /ws/txs {
            proxy_pass http://wsmonobackend;
            proxy_http_version      1.1;
            proxy_set_header        Upgrade \$http_upgrade;
            proxy_set_header        Connection "upgrade";
            proxy_set_header        Host \$http_host;
            proxy_set_header        X-Real-IP \$remote_addr;
    }

    location / {
            try_files \$uri \$uri/ /index.html;
            expires \$expires;
    }
}

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create symbolic link from nginx/sites-available to sites-enabled
#
echo
echo -e "${Y}Create symbolic link for bitfeed-ssl.conf in /etc/nginx/sites-enabled...${NC}"
ln -sf "${BITFEED_NGINX_SSL_CONF}" /etc/nginx/sites-enabled/
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

echo
echo -e "${Y}Installation all done!${NC}"
echo
echo -e "${LB}Systemd Service (as root or with sudo as user):${NC}"
echo -e " systemctl enable ${BITFEED_SERVICE} - enable service after boot\n" \
        "systemctl start ${BITFEED_SERVICE}  - start Bitfeed service\n" \
        "systemctl stop ${BITFEED_SERVICE}   - stop Bitfeed service\n" \
        "systemctl status ${BITFEED_SERVICE} - show service status" | column -t -s "+"
echo
echo -e "${LB}View Log:${NC}"
echo " journalctl -fu ${BITFEED_SERVICE}"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${BITFEED_DIR} + - Bitfeed base directory\n" \
        "${BITFEED_BACKEND_DIR} + - Bitfeed backend dir\n" \
        "${BITFEED_FRONTEND_DIR} + - Bitfeed frontend dir\n" \
        "+\n" \
        "${BITFEED_WEBROOT_DIR} + - Bitfeed nginx web root dir\n" \
        "+\n" \
        "${BITFEED_SERVICE_FILE} + - Bitfeed systemd service file\n" \
        "+\n" \
        "${BITFEED_NGINX_SSL_CONF} + - Bitfeed nginx ssl config\n" | column -t -s "+"
echo
echo
echo -e "${LB}Start the Bitfeed backend service via:${NC} systemctl start ${BITFEED_SERVICE}"
echo
echo -e "${LB}Open Bitfeed page in your browser via the following URL: ${NC}"
echo " https://${LOCAL_IP}:${BITFEED_SSL_PORT}"
echo

