#!/bin/bash

#
### install node_status (services and apps one-pager overwiew)
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
echo -e "${Y}This script will download and install node_status...${NC}"
echo
echo -e "${LB}The following steps will be executed in the process:${NC}"
echo "- Upgrade system to newest software (apt-get update / apt-get upgrade)"
echo "- Install missing dependencies via apt (${NODE_STAT_PKGS})"
echo "- Copy content of res/node_status directory into ${NODE_STAT_WEBROOT_DIR}"
echo "- Change permissions of web root directory (${NODE_STAT_WEBROOT_DIR}) for users www-data"
echo "- Create node_status systemd service file (${NODE_STAT_SERVICE_FILE})"
echo "- Create nginx node_status ssl config (${NODE_STAT_NGINX_SSL_CONF})"
echo "- Create php-fpm config file (${NODE_STAT_FPM_CONF_FILE}) and restart php-fpm service"
echo "- Check nginx configs and restart nginx web server"
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
for i in ${NODE_STAT_PKGS}; do
  echo -e "${LB}Installing package ${i} ...${NC}"
  apt-get -q install -y "${i}"
  echo -e "${LB}Done.${NC}"
done
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### copy the content of the res/node_status directory into web root dir (/var/www/html)
#
echo
echo -e "${Y}Copy the content of the res/node_status directory into the web root dir ${NODE_STAT_WEBROOT_DIR}...${NC}"
rm -rf "${NODE_STAT_WEBROOT_DIR}"
cp -r ../res/node_status "${NODE_STAT_WEBROOT_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### change permission of node_status web root dir to www-data
#
echo
echo -e "${Y}Change permission of node_status web dir (${NODE_STAT_WEBROOT_DIR}) for user www-data...${NC}"
chown -R www-data:www-data "${NODE_STAT_WEBROOT_DIR}"
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### create systemd service for for node_status
#
echo
echo -e "${Y}Create systemd service file for node_status (${NODE_STAT_SERVICE_FILE})...${NC}"
cat > "${NODE_STAT_SERVICE_FILE}"<< EOF
#
# node_status server monitor service file
#
[Unit]
Description=Node Status Server Monitor
After=network.target

[Service]
ExecStart=/usr/bin/ln -s /etc/nginx/sites-available/node_status-ssl.conf /etc/nginx/sites-enabled/node_status-ssl.conf
ExecStart=systemctl reload nginx

ExecStop=/usr/bin/rm -f /etc/nginx/sites-enabled/node_status-ssl.conf
ExecStop=systemctl reload nginx

RemainAfterExit=yes
Type=oneshot

[Install]
WantedBy=multi-user.target

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### nginx node_status ssl config
#
echo
echo -e "${Y}Write nginx node_status ssl config file (${NODE_STAT_NGINX_SSL_CONF})...${NC}"
cat > "${NODE_STAT_NGINX_SSL_CONF}"<< EOF

server {
        listen ${NODE_STAT_SSL_PORT} ssl;
        listen [::]:${NODE_STAT_SSL_PORT} ssl;
        server_name  _;
        root /var/www/html/node_status;
        index index.html index.htm index.php;

        ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
        ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
        ssl_session_timeout 4h;
        ssl_protocols TLSv1.3;
        ssl_prefer_server_ciphers on;

        access_log /var/log/nginx/nodeman.access.log;
        error_log /var/log/nginx/nodeman.error.log;

         location /node_status {
            try_files $uri $uri/ /index.php$is_args$args;
         }

         location ~ \.php$ {
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:/var/run/php7.4-fpm-node_status-site.sock;
            fastcgi_index index.php;
            include fastcgi.conf;
    }
}

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### write php-fpm config file (${NODE_STAT_FPM_CONF_FILE})
#
echo
echo -e "${Y}Write php-fpm config file (${NODE_STAT_FPM_CONF_FILE})...${NC}"
cat > "${NODE_STAT_FPM_CONF_FILE}"<< EOF

[node_status]
user = www-data
group = www-data
listen = /var/run/php7.4-fpm-node_status-site.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0666
php_admin_value[disable_functions] = exec,passthru,system
php_admin_flag[allow_url_fopen] = off
; Choose how the process manager will control the number of child processes.
pm = dynamic
pm.max_children = 5
pm.start_servers = 1
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.process_idle_timeout = 10s

EOF
echo -e "${G}Done.${NC}"

#-----------------------------------------------------------------

#
### restart php-fpm service
#
echo
echo -e "${Y}Restart php-fpm service...${NC}"
systemctl restart php7.4-fpm.service
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
echo -e " systemctl enable ${NODE_STAT_SERVICE} - enable service after boot\n" \
        "systemctl start ${NODE_STAT_SERVICE}  - start node_status service\n" \
        "systemctl stop ${NODE_STAT_SERVICE}   - stop node_status service\n" \
        "systemctl status ${NODE_STAT_SERVICE} - show service status" | column -t -s "+"
echo
echo -e "${LB}View Log:${NC}"
echo " journalctl -fu ${NODE_STAT_SERVICE}"
echo
echo -e "${LB}Files and Directories:${NC}"
echo -e " ${NODE_STAT_WEBROOT_DIR} + - node_status nginx web root dir\n" \
        "+\n" \
        "${NODE_STAT_SERVICE_FILE} + - node_status systemd service file\n" \
        "+\n" \
        "${NODE_STAT_FPM_CONF_FILE} + - node_status php-fpm config file\n" \
        "+\n" \
        "${NODE_STAT_NGINX_SSL_CONF} + - node_status nginx ssl config\n" | column -t -s "+"
echo
echo
echo -e "${LB}Open node_status page in your browser via the following URL: ${NC}"
echo " https://${LOCAL_IP}:${NODE_STAT_SSL_PORT}"
echo

