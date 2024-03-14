#!/bin/bash

########################################
# System and Service Status Information
########################################


#-----------------------------------------------------------------
# source/read config from repository
. <(curl -sL https://github.com/BtcAutoNode/BtcAutoNode/raw/master/CONFIG)
# or if you changed anything the config, copy CONFIG to here and comment out above line and uncomment the next line
#. CONFIG
#-----------------------------------------------------------------


clear
echo
echo -e "${Y}----------------------------------------------------------------------------------------------------------------${NC}"
echo -e "${LG}System Information:${NC}"
echo -e "${Y}----------------------------------------------------------------------------------------------------------------${NC}"
hostname=$(uname -n)
ipadd=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
uptime=$(uptime -p)
cmd5=$(free -m | awk 'NR==2{printf "Memory Usage : %s / %s MB (%.2f%%)\n", $3,$2,$3*100/$2 }')
cmd6=$(df -h | awk '$NF=="/"{printf "Disk Usage   : %.1f / %.1f GB (%s)\n", $3,$2,$5}')
cmd7=$(top -bn1 | grep load | awk '{printf "CPU Load     : %.2f % \n", $(NF-2)}')
cmd8="Uptime       : $uptime"
cmd9="Hostname   : $hostname"
cmd10="IP address : $ipadd"
sep='                          '
paste <(echo -e "${LB}Usage: \n$cmd5 \n$cmd6 \n$cmd7 \n$cmd8") <(echo -e "Network:${NC} \n$cmd9 \n$cmd10") | column -o "$sep" -s $'\t' -t
echo -e "${Y}----------------------------------------------------------------------------------------------------------------${NC}"
# Hardware / Linux Distro
cmd1="lscpu | egrep \"Architecture|CPU op|Model name|CPU MHz\" | sed s/\"          \"/\" \"/g"
cmd2="lsb_release -idrc"
paste <(echo -e "${LB}Hardware:" && eval "$cmd1") <(echo -e "Linux Distro:${NC}" && eval "$cmd2") | column -o '   ' -s $'\t' -t
echo -e "${Y}----------------------------------------------------------------------------------------------------------------${NC}"
echo -e "${LB}Kernel:${NC}"
uname -sr
echo -e "${Y}----------------------------------------------------------------------------------------------------------------${NC}"
echo -e "${LB}Memory:${NC}"
free -m
echo -e "${Y}----------------------------------------------------------------------------------------------------------------${NC}"
cmd3="df -h --output=source,size,used,avail,target --exclude-type=tmpfs"
cmd4="lsblk -o NAME,SIZE,MOUNTPOINT"
paste <(echo -e "${LB}Disk Space:" && eval "$cmd3") <(echo -e "Storage Devices:${NC}" && eval "$cmd4") | column -s $'\t' -t
echo -e "${Y}----------------------------------------------------------------------------------------------------------------${NC}"
echo -e "${LB}Status Services:${NC}"
SERVICE_NAME[1]="Bitcoin   ";SERVICE_HOST[1]="localhost";SERVICE_PORT[1]="8332"
SERVICE_NAME[2]="Fulcrum   ";SERVICE_HOST[2]="localhost";SERVICE_PORT[2]="50002"
SERVICE_NAME[3]="Mempool   ";SERVICE_HOST[3]="localhost";SERVICE_PORT[3]="8999"
SERVICE_NAME[4]="LND       ";SERVICE_HOST[4]="localhost";SERVICE_PORT[4]="8080"
SERVICE_NAME[5]="Thunderhub";SERVICE_HOST[5]="localhost";SERVICE_PORT[5]="3000"
SERVICE_NAME[6]="Glances   ";SERVICE_HOST[6]="localhost";SERVICE_PORT[6]="61208"
SERVICE_NAME[7]="Explorer  ";SERVICE_HOST[7]="localhost";SERVICE_PORT[7]="3002"
SERVICE_NAME[8]="Bitfeed   ";SERVICE_HOST[8]="localhost";SERVICE_PORT[8]="9999"
SERVICE_NAME[9]="Node Stats";SERVICE_HOST[9]="localhost";SERVICE_PORT[9]="4021"
  for ID in "${!SERVICE_NAME[@]}"
    do
      NAME="${SERVICE_NAME[$ID]}"
      HOST="${SERVICE_HOST[$ID]}"
      PORT="${SERVICE_PORT[$ID]}"

      STATUS=$((exec 3<>/dev/tcp/"$HOST"/"$PORT") &>/dev/null; echo "$?")

      if [ "$STATUS" = 0 ] ; then
          OUTPUT="${G}online ${NC} : $NAME [$PORT]"
      else
          OUTPUT="${R}offline${NC} : $NAME [$PORT]"
      fi
      echo -e "$OUTPUT"
  done
echo -e "${Y}----------------------------------------------------------------------------------------------------------------${NC}"
echo
