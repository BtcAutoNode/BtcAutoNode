#!/bin/bash

#
### download, verify, install Mempool (block explorer and visualizer)
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
echo -e "${Y}This script will download, verify and install Mempool...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Upgrade system to newest software (apt-get update / apt-get upgrade)"
echo "- Clone Mempool Github repository, version ${MEMPOOL_VERSION}"
echo "- Generate mysql password, create mempool db and grant priviledges"
echo "- Query rpcuser / rpcpass for backend config (by user interaction)"
echo "- Change Mempool backend config ${MEMPOOL_BACKEND_CONF}"
echo "- Build the Mempool backend part"
echo "- Build the Mempool frontend part"
echo "- Clean up npm caches from build (/root.cache)"
echo "- Create GeopIP dir and download GeoIP data for Mempool/LND (${MEMPOOL_DIR}/GeoIP)"
echo "- Move content of frontend/dist directory into ${MEMPOOL_WEBROOT_DIR}"
echo "- Change permissions of directories for users ${USER}, www-data"
echo "- Create systemd ${MEMPOOL_SERVICE} service file"
echo "- Create nginx configs, check nginx and restart nginx web server"
echo "- Change permissions for download, base, data dirs for user ${USER}"
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
### cd into homedir and download mempool git repository as user satoshi in /home/satoshi
#
echo
echo -e "${Y}Cd into ${HOME_DIR} and clone mempool git repository...${NC}"
cd "${HOME_DIR}"
# delete dir if exist
rm -rf "${MEMPOOL_DIR}"
git clone https://github.com/mempool/mempool
cd "${MEMPOOL_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### get the latest release from github and checkout git there
#
echo
echo -e "${Y}Get latest release and git checkout at this release...${NC}"
#latestrelease=$(curl -s https://api.github.com/repos/mempool/mempool/releases/latest|grep tag_name|head -1|cut -d '"' -f4)
latestrelease="v${MEMPOOL_VERSION}"
git -c advice.detachedHead=false checkout "${latestrelease}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### generate maria-db password
#
echo
echo -e "${Y}Generate maria-db password for database user...${NC}"
mariadb_pw=$(gpg --gen-random --armor 1 16)
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### Create a database for mempool and grant privileges
#
echo
echo -e "${Y}Create mempool db and grant priviledges to db user...${NC}"
mysql -e "create database IF NOT EXISTS mempool;"
mysql -e "grant all privileges on mempool.* to 'mempool'@'%' identified by '${mariadb_pw}';"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### request rpcuser and rpcpass from user again for the backend config
#
echo
echo -e "${LR}Please enter your ${NC}rpcuser${LR} used in bitcoind script and press the ${NC}<enter>${LR} key (for backend config):${NC}"
read -r RPCUSER
echo -e "${LR}Please enter your ${NC}rpcpass${LR} used in bitcoind script and press the ${NC}<enter>${LR} key (for backend config):${NC}"
read -r RPCPASS

#-----------------------------------------------------------------

#
### create mempool backend config
#
echo
echo -e "${Y}Write mempool backend conf...${NC}"
cat > "${MEMPOOL_BACKEND_CONF}"<< EOF
{
  "MEMPOOL": {
    "NETWORK": "mainnet",
    "BACKEND": "electrum",
    "HTTP_PORT": 8999,
    "SPAWN_CLUSTER_PROCS": 0,
    "API_URL_PREFIX": "/api/v1/",
    "POLL_RATE_MS": 2000,
    "CACHE_DIR": "./cache",
    "CLEAR_PROTECTION_MINUTES": 20,
    "RECOMMENDED_FEE_PERCENTILE": 50,
    "BLOCK_WEIGHT_UNITS": 4000000,
    "INITIAL_BLOCKS_AMOUNT": 8,
    "MEMPOOL_BLOCKS_AMOUNT": 8,
    "PRICE_FEED_UPDATE_INTERVAL": 3600,
    "USE_SECOND_NODE_FOR_MINFEE": false,
    "EXTERNAL_ASSETS": []
  },
  "CORE_RPC": {
    "HOST": "127.0.0.1",
    "PORT": 8332,
    "USERNAME": "${RPCUSER}",
    "PASSWORD": "${RPCPASS}"
  },
  "ELECTRUM": {
    "HOST": "127.0.0.1",
    "PORT": 50002,
    "TLS_ENABLED": true
  },
  "DATABASE": {
    "ENABLED": true,
    "HOST": "127.0.0.1",
    "PORT": 3306,
    "USERNAME": "mempool",
    "PASSWORD": "${mariadb_pw}",
    "DATABASE": "mempool"
  },
  "SOCKS5PROXY": {
    "ENABLED": true,
    "USE_ONION": true,
    "HOST": "127.0.0.1",
    "PORT": 9050
  },
  "MAXMIND": {
    "ENABLED": false,
    "GEOLITE2_CITY": "${MEMPOOL_DIR}/GeoIP/GeoLite2-City.mmdb",
    "GEOLITE2_ASN": "/${MEMPOOL_DIR}GeoIP/GeoLite2-ASN.mmdb",
    "GEOIP2_ISP": "${MEMPOOL_DIR}/GeoIP/GeoIP2-ISP.mmdb"
  },
  "LIGHTNING": {
    "ENABLED": false,
    "BACKEND": "lnd",
    "TOPOLOGY_FOLDER": "",
    "STATS_REFRESH_INTERVAL": 600,
    "GRAPH_REFRESH_INTERVAL": 600,
    "LOGGER_UPDATE_INTERVAL": 30
  },
  "LND": {
    "TLS_CERT_PATH": "/home/satoshi/.lnd/tls.cert",
    "MACAROON_PATH": "/home/satoshi/.lnd/data/chain/bitcoin/mainnet/readonly.macaroon",
    "REST_API_URL": "https://127.0.0.1:8080",
    "TIMEOUT": 10000
  },
  "PRICE_DATA_SERVER": {
    "CLEARNET_URL": "https://price.bisq.wiz.biz/getAllMarketPrices",
    "TOR_URL": "http://emzypricpidesmyqg2hc6dkwitqzaxrqnpkdg3ae2wef5znncu2ambqd.onion/getAllMarketPrices"
  }
}
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### build the mempool backend part
#
echo
echo -e "${Y}Build the backend part of mempool...${NC}"
echo -e "${LB}This can take several minutes!${NC}"
# set config
npm config set registry=https://registry.npmjs.com/
# install/build
cd "${MEMPOOL_BACKEND_DIR}"
npm install --omit=dev ## --no-install-links # npm@9.4.2 and later can omit the --no-install-links
npm run build
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
# create mempool frontend config
#cat > "${MEMPOOL_FRONTEND_CONF}"<< EOF
#{
#  "TESTNET_ENABLED": false,
#  "SIGNET_ENABLED": false,
#  "LIQUID_ENABLED": false,
#  "LIQUID_TESTNET_ENABLED": false,
#  "BISQ_ENABLED": false,
#  "BISQ_SEPARATE_BACKEND": false,
#  "ITEMS_PER_PAGE": 10,
#  "KEEP_BLOCKS_AMOUNT": 8,
#  "NGINX_PROTOCOL": "http",
#  "NGINX_HOSTNAME": "127.0.0.1",
#  "NGINX_PORT": "80",
#  "BLOCK_WEIGHT_UNITS": 4000000,
#  "MEMPOOL_BLOCKS_AMOUNT": 8,
#  "BASE_MODULE": "mempool",
#  "MEMPOOL_WEBSITE_URL": "https://mempool.space",
#  "LIQUID_WEBSITE_URL": "https://liquid.network",
#  "BISQ_WEBSITE_URL": "https://bisq.markets",
#  "MINING_DASHBOARD": true,
#  "AUDIT": false,
#  "MAINNET_BLOCK_AUDIT_START_HEIGHT": 0,
#  "TESTNET_BLOCK_AUDIT_START_HEIGHT": 0,
#  "SIGNET_BLOCK_AUDIT_START_HEIGHT": 0,
#  "LIGHTNING": true,
#  "HISTORICAL_PRICE": true
#}
#EOF

#-----------------------------------------------------------------

#
### build the mempool frontend part
#
echo
echo -e "${Y}Build the frontend part of mempool...${NC}"
echo -e "${LB}This can take quite some time!${NC}"
cd "${MEMPOOL_FRONTEND_DIR}"
npm install --omit=dev
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
# delete Cypress frontend test tool from .cache dir
rm -rf /root/.cache/Cypress
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### Create GeopIP dir and download GeoIP data for Mempool/LND
#
echo
echo -e "${Y}Create GeoIP dir in ${MEMPOOL_DIR} and download GeopIP files (for Mempool/Lnd)...${NC}"
cd "${MEMPOOL_DIR}"
mkdir -p GeoIP
cd GeoIP/
wget -O GeoLite2-City.mmdb https://raw.githubusercontent.com/mempool/geoip-data/master/GeoLite2-City.mmdb
wget -O GeoLite2-ASN.mmdb https://raw.githubusercontent.com/mempool/geoip-data/master/GeoLite2-ASN.mmdb
wget -O GeoIP2-ISP.mmdb https://github.com/naaanazar/geoIpInfo/raw/master/GeoIP2-ISP.mmdb
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### Move the content of the frontend/dist directory into /var/www/html/ directory (web root)
#
echo
echo -e "${Y}Move frontend dist dir into the web root dir...${NC}"
rm -rf "${NGINX_WEBROOT_DIR}"/mempool
mv "${MEMPOOL_FRONTEND_DIR}"/dist/mempool "${NGINX_WEBROOT_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permission of mempool web root dir to www-data
#
echo
echo -e "${Y}Change permission of mempool web dir for www-data...${NC}"
chown -R www-data:www-data "${MEMPOOL_WEBROOT_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permissions of the /home/satoshi/mempool dir to user satoshi
#
echo
echo -e "${Y}Change permissions of ${MEMPOOL_DIR} to user ${USER}...${NC}"
chown -R "${USER}":"${USER}" "${MEMPOOL_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create systemd service for for mempool
#
echo
echo -e "${Y}Create systemd service file for Mempool...${NC}"
cat > "${MEMPOOL_SERVICE_FILE}"<< EOF
[Unit]
Description=mempool
After=${BITCOIN_SERVICE_FILE}

[Service]
WorkingDirectory=${MEMPOOL_BACKEND_DIR}
ExecStart=/usr/bin/node --max-old-space-size=2048 dist/index.js
User=${USER}
Group=${USER}

# Restart on failure but no more than default times (DefaultStartLimitBurst=5) every 10 minutes (600 seconds). Otherwise stop
Restart=on-failure
RestartSec=600

# Hardening measures
PrivateTmp=true
ProtectSystem=full
NoNewPrivileges=true
PrivateDevices=true

[Install]
WantedBy=multi-user.target
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### nginx mempool ssl config
#
echo
echo -e "${Y}Write nginx Mempool ssl config file...${NC}"
cat > "${MEMPOOL_NGINX_SSL_CONF}"<< EOF
# mempool ssl conf, put into sites-availabe

        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;

        map \$http_accept_language \$header_lang {
                default en-US;
                ~*^en-US en-US;
                ~*^en en-US;
                ~*^ar ar;
                ~*^ca ca;
                ~*^cs cs;
                ~*^de de;
                ~*^es es;
                ~*^fa fa;
                ~*^fr fr;
                ~*^ko ko;
                ~*^it it;
                ~*^he he;
                ~*^ka ka;
                ~*^hu hu;
                ~*^mk mk;
                ~*^nl nl;
                ~*^ja ja;
                ~*^nb nb;
                ~*^pl pl;
                ~*^pt pt;
                ~*^ro ro;
                ~*^ru ru;
                ~*^sl sl;
                ~*^fi fi;
                ~*^sv sv;
                ~*^th th;
                ~*^tr tr;
                ~*^uk uk;
                ~*^vi vi;
                ~*^zh zh;
                ~*^hi hi;
        }

        map \$cookie_lang \$lang {
                default \$header_lang;
                ~*^en-US en-US;
                ~*^en en-US;
                ~*^ar ar;
                ~*^ca ca;
                ~*^cs cs;
                ~*^de de;
                ~*^es es;
                ~*^fa fa;
                ~*^fr fr;
                ~*^ko ko;
                ~*^it it;
                ~*^he he;
                ~*^ka ka;
                ~*^hu hu;
                ~*^mk mk;
                ~*^nl nl;
                ~*^ja ja;
                ~*^nb nb;
                ~*^pl pl;
                ~*^pt pt;
                ~*^ro ro;
                ~*^ru ru;
                ~*^sl sl;
                ~*^fi fi;
                ~*^sv sv;
                ~*^th th;
                ~*^tr tr;
                ~*^uk uk;
                ~*^vi vi;
                ~*^zh zh;
                ~*^hi hi;
        }

server {
    listen ${MEMPOOL_SSL_PORT} ssl;
    listen [::]:${MEMPOOL_SSL_PORT} ssl;
    server_name _;
    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
    ssl_session_timeout 4h;
    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers on;

    include /etc/nginx/snippets/nginx-mempool.conf;
}
EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create symbolic link from nginx/sites-available to sites-enabled
#
echo
echo -e "${Y}Create symbolic link for mempool-ssl.conf in sites-enabled...${NC}"
ln -sf "${MEMPOOL_NGINX_SSL_CONF}" /etc/nginx/sites-enabled/
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### nginx mempool app config snippet
#
echo
echo -e "${Y}Create nginx mempool app config snippet...${NC}"
mkdir -p /etc/nginx/snippets
cp "${MEMPOOL_DIR}/nginx-mempool.conf" "${MEMPOOL_NGINX_APP_CONF}"
# change root path to NGINX_WEBROOT_DIR
sed -i 's/root.*/root \/var\/www\/html\/mempool\/browser;/g' "${MEMPOOL_NGINX_APP_CONF}"
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
echo -e " systemctl enable ${MEMPOOL_SERVICE} - enable service after boot\n" \
        "systemctl start ${MEMPOOL_SERVICE}  - start Mempool service\n" \
        "systemctl stop ${MEMPOOL_SERVICE}   - stop Mempool service\n" \
        "systemctl status ${MEMPOOL_SERVICE} - show service status" | column -t -s "+"
echo
echo -e "${LB}View Log:${NC}"
echo " journalctl -fu ${MEMPOOL_SERVICE}"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${MEMPOOL_DIR} + - Mempool base directory\n" \
        "${MEMPOOL_BACKEND_DIR} + - Mempool backend dir\n" \
        "${MEMPOOL_FRONTEND_DIR} + - Mempool frontend dir\n" \
        "${MEMPOOL_BACKEND_CONF} + - Mempool backend config file\n" \
        "+\n" \
        "${MEMPOOL_SERVICE_FILE} + - Mempool systemd service file\n" \
        "+\n" \
        "${MEMPOOL_NGINX_SSL_CONF} + - Mempool nginx ssl config\n" \
        "${MEMPOOL_NGINX_APP_CONF} + - Mempool nginx app config" | column -t -s "+"
echo
echo
echo -e "${LB}Open mempool page in your browser via the following URL: ${NC}"
echo " https://${LOCAL_IP}:4080"
echo
