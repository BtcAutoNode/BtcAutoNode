#!/bin/bash

#
### download and install Lightning Network Visualizer (a graph visualization tool to draw the lightning network)
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
echo -e "${Y}This script will download and install LN-Visualizer...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Upgrade system to newest software (apt-get update / apt-get upgrade)"
#echo "- Install missing dependencies via apt (${LNVIS_PKGS})"
echo "- Clone LN-Visualizer Github repository, version ${LNVIS_VERSION}"
echo "- Build the LN-Visualizer backend part (api)"
echo "- Build the LN-Visualizer frontend part (client)"
echo "- Clean up npm caches from build (/root/.cache)"
echo "- Move content of dist directory into ${LNVIS_WEBROOT_DIR}"
echo "- Change permissions of directories for users ${USER}, www-data"
echo "- Create systemd ${LNVIS_SERVICE} service file"
echo "- Create nginx configs, check nginx and restart nginx web server"
echo "- Change permissions for the LN-Visualizer base dir ${LNVIS_DIR} for user ${USER}"
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
#echo
#echo -e "${Y}Installing dependencies...${NC}"
#for i in ${LNVIS_PKGS}; do
#  echo -e "${LB}Installing package ${i} ...${NC}"
#  apt-get -q install -y "${i}"
#  echo -e "${LB}Done.${NC}"
#done
#echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### cd into homedir and download ln-visualizer git repository as user satoshi in /home/satoshi
#
echo
echo -e "${Y}Cd into ${HOME_DIR} and clone LN-Visualizer git repository...${NC}"
cd "${HOME_DIR}"
# delete dir if exist
rm -rf "${LNVIS_DIR}"
git clone https://github.com/MaxKotlan/LN-Visualizer.git
cd "${LNVIS_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### get the latest release from github and checkout git there
#
echo
echo -e "${Y}Get latest release and git checkout at this release...${NC}"
latestrelease="v${LNVIS_VERSION}"
git -c advice.detachedHead=false checkout "${latestrelease}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### build the ln-visualizer frontend part
#
echo
echo -e "${Y}Build the frontend part of LN-Visualizer...${NC}"
echo -e "${LB}This can take some time!${NC}"
cd "${LNVIS_FRONTEND_DIR}"
# update npm (from warnings)
npm install -g npm@"${NPM_UPD_VER}"
npm install
npm run build
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### write backend/api config for ln-visualizer
#
echo
echo -e "${Y}Write/overwrite backend/api config for LN-Visualizer (${LNVIS_BACKEND_CONF})...${NC}"
cat > "${LNVIS_BACKEND_CONF}"<< EOF

{
    "lndConfig": {
        "macaroon": {
            "cert": "base64 encoded tls.cert",
            "macaroon": "base64 encoded admin.macaroon",
            "socket": "127.0.0.1:10009"
        },
        "cert_file": "${LND_CERT_FILE}",
        "macaroon_file": "${LND_READONLY_MACAROON_FILE}"
    },
    "positionAlgorithm": "gradient-descent",
    "initSyncChunkSize": 4096,
    "gradientDescentSettings": {
        "iterations": 50,
        "learningRate": 1.0,
        "logRate": 10,
        "maxConnectedNodeDistance": 0.1,
        "minConnectedNodeDistance": 0.04,
        "invertConnectedRange": true,
        "shouldLog": true
    },
    "benchmarkMode": {
        "enabled": false,
        "nodeCount": 18000,
        "channelCount": 90000
    },
    "port": 5647,
    "host": "0.0.0.0"
}

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### build the ln-visualizer backend part (api)
#
echo
echo -e "${Y}Build the backend part of LN-Visualizer (api)...${NC}"
echo -e "${LB}This can take several minutes!${NC}"
# install/build
cd "${LNVIS_BACKEND_DIR}"
npm install
npm install -g rimraf typescript
npm run build
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

# version information in package.json is 0.0.5, not 0,0,28
# overwrite with release version number (as used in version script)
sed -i "s/0.0.5/${LNVIS_VERSION}/g" "${LNVIS_DIR}"/package.json
#sed -i "s/0.0.5/${LNVIS_VERSION}/g" ${LNVIS_DIR}/package-lock.json
#-----------------------------------------------------------------

#
### Move the content of the ${LNVIS_DIR}/dist directory into /var/www/html/ directory (web root)
#
echo
echo -e "${Y}Move content of ${LNVIS_DIR}/dist dir into the web root dir...${NC}"
rm -rf "${LNVIS_WEBROOT_DIR}"
mv "${LNVIS_FRONTEND_DIR}"/dist/ln-visualizer "${LNVIS_WEBROOT_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permission of ln-visualizer web root dir to www-data
#
echo
echo -e "${Y}Change permission of LN-Visualizer web dir ${LNVIS_WEBROOT_DIR} for user www-data...${NC}"
chown -R www-data:www-data "${LNVIS_WEBROOT_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permissions of the /home/satoshi/LN-Visualizer dir to user satoshi
#
echo
echo -e "${Y}Change permissions of ${LNVIS_DIR} to user ${USER}...${NC}"
chown -R "${USER}":"${USER}" "${LNVIS_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create systemd service for for ln-visualizer
#
echo
echo -e "${Y}Create systemd service file for LN-Visualizer (${LNVIS_SERVICE_FILE})...${NC}"
cat > "${LNVIS_SERVICE_FILE}"<< EOF

[Unit]
Description=Lightning Network Visualizer
After=network.target
Requires=network.target lnd.service

[Service]
Type=simple
User=${USER}
Group=${USER}
Restart=on-failure
RestartSec=600

WorkingDirectory=${LNVIS_BACKEND_DIR}

# start command
ExecStart=/usr/bin/npm run start

[Install]
WantedBy=multi-user.target

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### nginx ln-visualizer ssl config
#
echo
echo -e "${Y}Write nginx LN-Visualizer ssl config file (${LNVIS_NGINX_SSL_CONF})...${NC}"
cat > "${LNVIS_NGINX_SSL_CONF}"<< EOF
# LN-Visualizer nginx config

server {
    listen ${LNVIS_SSL_PORT} ssl;
    listen [::]:${LNVIS_SSL_PORT} ssl;
    server_name _;
    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
    ssl_session_timeout 4h;
    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers on;

    root   /var/www/html/ln-visualizer;
    index  index.html index.htm;
    include /etc/nginx/mime.types;

    gzip on;
    gzip_min_length 1000;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css application/json application/javascript application/x-javascript text/xml application/xml application/xml+rss text/javascript;

    location /api/ {
        proxy_pass         http://127.0.0.1:5647;
        proxy_redirect     off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Host \$server_name;
        proxy_read_timeout  36000s;
    }

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location ~ .*\.css\$|.*\.js$|.*\.woff2|.*\.svg {
        add_header Cache-Control 'max-age=31449600'; # one year
    }

    location ~ \.html\$|.*\.json$ {
      add_header Cache-Control "private, no-cache, no-store, must-revalidate";
      add_header Expires "Sat, 01 Jan 2000 00:00:00 GMT";
      add_header Pragma no-cache;
    }
}

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create symbolic link from nginx/sites-available to sites-enabled
#
echo
echo -e "${Y}Create symbolic link for ln-visualizer-ssl.conf in /etc/nginx/sites-enabled...${NC}"
ln -sf "${LNVIS_NGINX_SSL_CONF}" /etc/nginx/sites-enabled/
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
echo -e " systemctl enable ${LNVIS_SERVICE} - enable service after boot\n" \
        "systemctl start ${LNVIS_SERVICE}  - start LN-Visualizer service\n" \
        "systemctl stop ${LNVIS_SERVICE}   - stop LN-Visualizer service\n" \
        "systemctl status ${LNVIS_SERVICE} - show service status" | column -t -s "+"
echo
echo -e "${LB}View Log:${NC}"
echo " journalctl -fu ${LNVIS_SERVICE}"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${LNVIS_DIR} + - LN-Visualizer base directory\n" \
        "${LNVIS_BACKEND_DIR} + - LN-Visualizer backend dir\n" \
        "${LNVIS_FRONTEND_DIR} + - LN-Visualizer frontend dir\n" \
        "+\n" \
        "${LNVIS_WEBROOT_DIR} + - LN-Visualizer nginx web root dir\n" \
        "+\n" \
        "${LNVIS_SERVICE_FILE} + - LN-Visualizer systemd service file\n" \
        "+\n" \
        "${LNVIS_NGINX_SSL_CONF} + - LN-Visualizer nginx ssl config\n" | column -t -s "+"
echo
echo
echo -e "${LB}Start the LN-Visualizer backend service via:${NC} systemctl start ${LNVIS_SERVICE}"
echo
echo -e "${LB}Open LN-Visualizer page in your browser via the following URL: ${NC}"
echo " https://${LOCAL_IP}:${LNVIS_SSL_PORT}"
echo

