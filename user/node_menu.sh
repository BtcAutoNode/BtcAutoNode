#!/bin/bash

########################################
# Fullnode manager menu
########################################


#-----------------------------------------------------------------
# source/read config from repository
. <(curl -sL https://github.com/BtcAutoNode/BtcAutoNode/raw/master/CONFIG)
# or if you changed anything in the config, copy CONFIG to the dir this file is in  and comment out above line and uncomment the next line
#. CONFIG
#-----------------------------------------------------------------

#
# Options
#
# menu separator (spaces to show entries vertically, not horizontally. change for your screen size and liking)
menusep="                                                                                                                                                           "
# number of rows shown from the log file
rows="30"

#-------------------------------------------------------------------------------------------

### Functions

#
# check_continue
#
function check_continue() {
   # check_continue
   echo; echo
   echo -e "${LG}Paused: Press any key to continue${NC}" # light green color
   read -n 1 -s -r
}

#
# function to handle systemd service operations
#
function execute_service() {
   local mode=$1
   local service=$2
   echo; echo
   # check_go_and_abort
   echo -e "${LG}Press any key to continue / \e[91mQ\e[0m \e[92mto abort${NC}" # light green color
   read -n 1 -s -r input
   if [ "q" = "$input" ]; then
     echo; echo
     echo -e "${LR}Action aborted. (wait 2 secs)${NC}" # light red color
     sleep 2
     return
   fi
   # service operations
   echo; echo
   if [ "$mode" = "start" ]; then
     echo -e "${LP} Trying to start service...${NC}" # light magenta
     sudo systemctl start "$service"
   fi
   if [ "$mode" = "stop" ]; then
     echo -e "${LP} Trying to stop service...${NC}" # light magenta
     sudo systemctl stop "$service"
   fi
   if [ "$mode" = "status" ]; then
     echo -e "${LP} Status of service...${NC}" # light magenta
     sudo systemctl status "$service"
   fi
   if [ "$mode" = "restart" ]; then
     echo -e "${LP} Trying to restart service...${NC}" # light magenta
     sudo systemctl restart "$service"
   fi
   echo -e "${LP} Done.${NC}" # light magenta
   check_continue
}
#
# function to handle log file editing
#
function edit_config() {
   echo; echo
   # check_go_and_abort
   echo -e "${LG}Press any key to continue / ${LR}q${NC} to abort${NC}"
   read -n 1 -s -r input
   if [ "q" = "$input" ]; then
     echo; echo
     echo -e "${LR}Action aborted. (wait 2 secs)${NC}" # light red color
     sleep 2
     return
   fi
   # edit file
   local conffile=$1
   nano "$conffile"
}

#
# function to show systemd service journal
#
function show_journal() {
   local service=$1
   sudo journalctl -fu "$service" -n "$rows" | less
}

#
# additional info for a command/option (e.g. tell key to leave)
#
function additional_info()
{
   local mode=$1
   echo; echo
   if [ "$mode" = "log" ]; then
     echo -e "${LP} !! Later leave the logfile with ${NC}CTRL-C${LP}, then ${NC}q${LP} !!${NC}" # light magenta
   fi
   check_continue
}

#
# check app versions calling version_check.sh script
#
function check_versions() {
   clear
   "${HOME_DIR}"/version_check.sh
   check_continue
}

#
# show system/service overview calling system_info.sh script
#
function sys_info() {
   clear
   "${HOME_DIR}"/system_info.sh
   check_continue
}

#-------------------------------------------------------------------------------------------

### Submenus
bitcoindmenu() {
 bitcoindmenuoptions=(
         "     [  1  ] -=  Start Service      =-$menusep"
         "     [  2  ] -=  Stop Service       =-"
         "     [  3  ] -=  Status Service     =-"
         "     [  4  ] -=  Restart Service    =-"
         "     [  -  ] -=  -----------------  =-"
         "     [  5  ] -=  Tail Log File      =-"
         "     [  6  ] -=  Edit Config        =-"
         "     [  -  ] -=  -----------------  =-"
         "     [  q  ] -=  Back to Main Menu  =-"
 )
 while true
  do
    clear
    echo; echo; echo; echo;
    echo -e "${G}---------------------------------------------------------"
    echo -e "${G}  Full Node Control - Bitcoind Menu"
    echo -e "${G}---------------------------------------------------------"
    echo -e "${NC}Please enter your choice:"
    echo -e "${BR}"
    select reply in "${bitcoindmenuoptions[@]}";
    do
      echo -e "${NC}" # reset color
      case $REPLY in
        1) # Start Service
           execute_service "start" "${BITCOIN_SERVICE}"
           break
           ;;
        2) # Stop Service
           execute_service "stop" "${BITCOIN_SERVICE}"
           break
           ;;
        3) # Status Service
           execute_service "status" "${BITCOIN_SERVICE}"
           break
           ;;
        4) # Restart Service
           execute_service "restart" "${BITCOIN_SERVICE}"
           break
           ;;
        5) # Tail Log File
           additional_info "log"
           tail -n "$rows" -f "${BITCOIN_LOG_FILE}" | less
           break
           ;;
        6) # Edit Config File
           edit_config "${BITCOIN_CONF_FILE}"
           break
           ;;
        q) # back to main menu
           break 2
           ;;
        *) echo 'Please select an option.' >&2
      esac
      break
    done
  done
}

fulcrummenu() {
 fulcrummenuoptions=(
         "     [  1  ] -=  Start Service      =-$menusep"
         "     [  2  ] -=  Stop Service       =-"
         "     [  3  ] -=  Status Service     =-"
         "     [  4  ] -=  Restart Service    =-"
         "     [  -  ] -=  -----------------  =-"
         "     [  5  ] -=  Tail Journal Log   =-"
         "     [  6  ] -=  Edit Config        =-"
         "     [  -  ] -=  -----------------  =-"
         "     [  q  ] -=  Back to Main Menu  =-"
 )
 while true
  do
    clear
    echo; echo; echo; echo;
    echo -e "${G}---------------------------------------------------------"
    echo -e "${G}  Full Node Control - Fulcrum Menu"
    echo -e "${G}---------------------------------------------------------"
    echo -e "${NC}Please enter your choice:"
    echo -e "${BR}"
    select reply in "${fulcrummenuoptions[@]}";
    do
      echo -e "${NC}" # reset color
      case $REPLY in
       1) # Start Service
           execute_service "start" "${FULCRUM_SERVICE}"
           break
           ;;
        2) # Stop Service
           execute_service "stop" "${FULCRUM_SERVICE}"
           break
           ;;
        3) # Status Service
           execute_service "status" "${FULCRUM_SERVICE}"
           break
           ;;
        4) # Restart Service
           execute_service "restart" "${FULCRUM_SERVICE}"
           break
           ;;
        5) # Tail Journal Log
           additional_info "log"
           show_journal "${FULCRUM_SERVICE}"
           break
           ;;
        6) # Edit Config File
           edit_config "${FULCRUM_CONF_FILE}"
           break
           ;;
        q) # back to main menu
           break 2
           ;;
        *) echo 'Please select an option.' >&2
      esac
      break
    done
  done
}

mempoolmenu() {
 mempoolmenuoptions=(
         "     [  1  ] -=  Start Service      =-$menusep"
         "     [  2  ] -=  Stop Service       =-"
         "     [  3  ] -=  Status Service     =-"
         "     [  4  ] -=  Restart Service    =-"
         "     [  -  ] -=  -----------------  =-"
         "     [  5  ] -=  Tail Journal Log   =-"
         "     [  6  ] -=  Show Web URL       =-"
         "     [  7  ] -=  Edit Config        =-"
         "     [  -  ] -=  -----------------  =-"
         "     [  q  ] -=  Back to Main Menu  =-"
 )

 while true
  do
    clear
    echo; echo; echo; echo;
    echo -e "${G}---------------------------------------------------------"
    echo -e "${G}  Full Node Control - Mempool Menu"
    echo -e "${G}---------------------------------------------------------"
    echo -e "${NC}Please enter your choice:"
    echo -e "${BR}"
    select reply in "${mempoolmenuoptions[@]}";
    do
      echo -e "${NC}" # reset color
      case $REPLY in
        1) # Start Service
           execute_service "start" "${MEMPOOL_SERVICE}"
           break
           ;;
        2) # Stop Service
           execute_service "stop" "${MEMPOOL_SERVICE}"
           break
           ;;
        3) # Status Service
           execute_service "status" "${MEMPOOL_SERVICE}"
           break
           ;;
        4) # Restart Service
           execute_service "restart" "${MEMPOOL_SERVICE}"
           break
           ;;
        5) # Tail Journal Log
           additional_info "log"
           show_journal "${MEMPOOL_SERVICE}"
           break
           ;;
        6) # Show Web URL
           echo; echo -e "Web URL (CTRL-Click): \e[1;35mhttps://${LOCAL_IP}:${MEMPOOL_SSL_PORT}/en/\e[0m"
           check_continue
           break
           ;;
        7) # Edit Config File
           edit_config "${MEMPOOL_BACKEND_CONF}"
           break
           ;;
        q) # back to main menu
           break 2
           ;;
        *) echo 'Please select an option.' >&2
      esac
      break
    done
  done
}

lndmenu() {
 lndmenuoptions=(
         "     [  1  ] -=  Start Service      =-$menusep"
         "     [  2  ] -=  Stop Service       =-"
         "     [  3  ] -=  Status Service     =-"
         "     [  4  ] -=  Restart Service    =-"
         "     [  -  ] -=  -----------------  =-"
         "     [  5  ] -=  Tail Journal Log   =-"
         "     [  7  ] -=  Edit Config        =-"
         "     [  -  ] -=  -----------------  =-"
         "     [  q  ] -=  Back to Main Menu  =-"
 )

 while true
  do
    clear
    echo; echo; echo; echo;
    echo -e "${G}---------------------------------------------------------"
    echo -e "${G}  Full Node Control - LND Menu"
    echo -e "${G}---------------------------------------------------------"
    echo -e "${NC}Please enter your choice:"
    echo -e "${BR}"
    select reply in "${lndmenuoptions[@]}";
    do
      echo -e "${NC}" # reset color
      case $REPLY in
        1) # Start Service
           execute_service "start" "${LND_SERVICE}"
           break
           ;;
        2) # Stop Service
           execute_service "stop" "${LND_SERVICE}"
           break
           ;;
        3) # Status Service
           execute_service "status" "${LND_SERVICE}"
           break
           ;;
        4) # Restart Service
           execute_service "restart" "${LND_SERVICE}"
           break
           ;;
        5) # Tail Journal Log
           additional_info "log"
           show_journal "${LND_SERVICE}"
           break
           ;;
        6) # Edit Config File
           edit_config "${LND_CONF_FILE}"
           break
           ;;
        q) # back to main menu
           break 2
           ;;
        *) echo 'Please select an option.' >&2
      esac
      break
    done
  done
}

thunderhubmenu() {
 thunderhubmenuoptions=(
         "     [  1  ] -=  Start Service      =-$menusep"
         "     [  2  ] -=  Stop Service       =-"
         "     [  3  ] -=  Status Service     =-"
         "     [  4  ] -=  Restart Service    =-"
         "     [  -  ] -=  -----------------  =-"
         "     [  5  ] -=  Tail Journal Log   =-"
         "     [  6  ] -=  Show Web URL       =-"
         "     [  7  ] -=  Edit .env Config   =-"
         "     [  8  ] -=  Edit yaml Config   =-"
         "     [  -  ] -=  -----------------  =-"
         "     [  q  ] -=  Back to Main Menu  =-"
 )

 while true
  do
    clear
    echo; echo; echo; echo;
    echo -e "${G}---------------------------------------------------------"
    echo -e "${G}  Full Node Control - Thunderhub Menu"
    echo -e "${G}---------------------------------------------------------"
    echo -e "${NC}Please enter your choice:"
    echo -e "${BR}"
    select reply in "${thunderhubmenuoptions[@]}";
    do
      echo -e "${NC}" # reset color
      case $REPLY in
        1) # Start Service
           execute_service "start" "${THH_SERVICE}"
           break
           ;;
        2) # Stop Service
           execute_service "stop" "${THH_SERVICE}"
           break
           ;;
        3) # Status Service
           execute_service "status" "${THH_SERVICE}"
           break
           ;;
        4) # Restart Service
           execute_service "restart" "${THH_SERVICE}"
           break
           ;;
        5) # Tail Journal Log
           additional_info "log"
           show_journal "${THH_SERVICE}"
           break
           ;;
        6) # Show Web URL
           echo; echo -e "Web URL (CTRL-Click): \e[1;35mhttps://${LOCAL_IP}:${THH_SSL_PORT}\e[0m"
           check_continue
           break
           ;;
        7) # Edit Config File
           edit_config "${THH_ENV_CONF_FILE}"
           break
           ;;
        8) # Edit Config File
           edit_config "${THH_YAML_CONF_FILE}"
           break
           ;;

        q) # back to main menu
           break 2
           ;;
        *) echo 'Please select an option.' >&2
      esac
      break
    done
  done
}

glancesmenu() {
 glancesmenuoptions=(
         "     [  1  ] -=  Start Service      =-$menusep"
         "     [  2  ] -=  Stop Service       =-"
         "     [  3  ] -=  Status Service     =-"
         "     [  4  ] -=  Restart Service    =-"
         "     [  -  ] -=  -----------------  =-"
         "     [  5  ] -=  Tail Journal Log   =-"
         "     [  6  ] -=  Show Web URL       =-"
         "     [  -  ] -=  -----------------  =-"
         "     [  q  ] -=  Back to Main Menu  =-"
 )

 while true
  do
    clear
    echo; echo; echo; echo;
    echo -e "${G}---------------------------------------------------------"
    echo -e "${G}  Full Node Control - Glances Menu"
    echo -e "${G}---------------------------------------------------------"
    echo -e "${NC}Please enter your choice:"
    echo -e "${BR}"
    select reply in "${glancesmenuoptions[@]}";
    do
      echo -e "${NC}" # reset color
      case $REPLY in
        1) # Start Service
           execute_service "start" "${GLANCES_SERVICE}"
           break
           ;;
        2) # Stop Service
           execute_service "stop" "${GLANCES_SERVICE}"
           break
           ;;
        3) # Status Service
           execute_service "status" "${GLANCES_SERVICE}"
           break
           ;;
        4) # Restart Service
           execute_service "restart" "${GLANCES_SERVICE}"
           break
           ;;
        5) # Tail Journal Log
           additional_info "log"
           show_journal "${GLANCES_SERVICE}"
           break
           ;;
        6) # Show Web URL
           echo; echo -e "Web URL (CTRL-Click): \e[1;35mhttps://${LOCAL_IP}:${GLANCES_SSL_PORT}\e[0m"
           check_continue
           break
           ;;
        q) # back to main menu
           break 2
           ;;
        *) echo 'Please select an option.' >&2
      esac
      break
    done
  done
}

bitfeedmenu() {
 bitfeedmenuoptions=(
         "     [  1  ] -=  Start Service      =-$menusep"
         "     [  2  ] -=  Stop Service       =-"
         "     [  3  ] -=  Status Service     =-"
         "     [  4  ] -=  Restart Service    =-"
         "     [  -  ] -=  -----------------  =-"
         "     [  5  ] -=  Tail Journal Log   =-"
         "     [  6  ] -=  Show Web URL       =-"
         "     [  -  ] -=  -----------------  =-"
         "     [  q  ] -=  Back to Main Menu  =-"
 )

 while true
  do
    clear
    echo; echo; echo; echo;
    echo -e "${G}---------------------------------------------------------"
    echo -e "${G}  Full Node Control - Bitfeed Menu"
    echo -e "${G}---------------------------------------------------------"
    echo -e "${NC}Please enter your choice:"
    echo -e "${BR}"
    select reply in "${bitfeedmenuoptions[@]}";
    do
      echo -e "${NC}" # reset color
      case $REPLY in
        1) # Start Service
           execute_service "start" "${BITFEED_SERVICE}"
           break
           ;;
        2) # Stop Service
           execute_service "stop" "${BITFEED_SERVICE}"
           break
           ;;
        3) # Status Service
           execute_service "status" "${BITFEED_SERVICE}"
           break
           ;;
        4) # Restart Service
           execute_service "restart" "${BITFEED_SERVICE}"
           break
           ;;
        5) # Tail Journal Log
           additional_info "log"
           show_journal "${BITFEED_SERVICE}"
           break
           ;;
        6) # Show Web URL
           echo; echo -e "Web URL (CTRL-Click): \e[1;35mhttps://${LOCAL_IP}:${BITFEED_SSL_PORT}\e[0m"
           check_continue
           break
           ;;
        q) # back to main menu
           break 2
           ;;
        *) echo 'Please select an option.' >&2
      esac
      break
    done
  done
}

explorermenu() {
 explorermenuoptions=(
         "     [  1  ] -=  Start Service      =-$menusep"
         "     [  2  ] -=  Stop Service       =-"
         "     [  3  ] -=  Status Service     =-"
         "     [  4  ] -=  Restart Service    =-"
         "     [  -  ] -=  -----------------  =-"
         "     [  5  ] -=  Tail Journal Log   =-"
         "     [  6  ] -=  Show Web URL       =-"
         "     [  -  ] -=  -----------------  =-"
         "     [  q  ] -=  Back to Main Menu  =-"
 )

 while true
  do
    clear
    echo; echo; echo; echo;
    echo -e "${G}---------------------------------------------------------"
    echo -e "${G}  Full Node Control - RPC-Explorer Menu"
    echo -e "${G}---------------------------------------------------------"
    echo -e "${NC}Please enter your choice:"
    echo -e "${BR}"
    select reply in "${explorermenuoptions[@]}";
    do
      echo -e "${NC}" # reset color
      case $REPLY in
        1) # Start Service
           execute_service "start" "${EXPLORER_SERVICE}"
           break
           ;;
        2) # Stop Service
           execute_service "stop" "${EXPLORER_SERVICE}"
           break
           ;;
        3) # Status Service
           execute_service "status" "${EXPLORER_SERVICE}"
           break
           ;;
        4) # Restart Service
           execute_service "restart" "${EXPLORER_SERVICE}"
           break
           ;;
        5) # Tail Journal Log
           additional_info "log"
           show_journal "${EXPLORER_SERVICE}"
           break
           ;;
        6) # Show Web URL
           echo; echo -e "Web URL (CTRL-Click): \e[1;35mhttps://${LOCAL_IP}:${EXPLORER_SSL_PORT}\e[0m"
           check_continue
           break
           ;;
        q) # back to main menu
           break 2
           ;;
        *) echo 'Please select an option.' >&2
      esac
      break
    done
  done
}

nodestatusmenu() {
 nodestatusmenuoptions=(
         "     [  1  ] -=  Start Service      =-$menusep"
         "     [  2  ] -=  Stop Service       =-"
         "     [  3  ] -=  Status Service     =-"
         "     [  4  ] -=  Restart Service    =-"
         "     [  -  ] -=  -----------------  =-"
         "     [  5  ] -=  Tail Journal Log   =-"
         "     [  6  ] -=  Show Web URL       =-"
         "     [  -  ] -=  -----------------  =-"
         "     [  q  ] -=  Back to Main Menu  =-"
 )

 while true
  do
    clear
    echo; echo; echo; echo;
    echo -e "${G}---------------------------------------------------------"
    echo -e "${G}  Full Node Control - Node Status Menu"
    echo -e "${G}---------------------------------------------------------"
    echo -e "${NC}Please enter your choice:"
    echo -e "${BR}"
    select reply in "${nodestatusmenuoptions[@]}";
    do
      echo -e "${NC}" # reset color
      case $REPLY in
        1) # Start Service
           execute_service "start" "${NODE_STAT_SERVICE}"
           break
           ;;
        2) # Stop Service
           execute_service "stop" "${NODE_STAT_SERVICE}"
           break
           ;;
        3) # Status Service
           execute_service "status" "${NODE_STAT_SERVICE}"
           break
           ;;
        4) # Restart Service
           execute_service "restart" "${NODE_STAT_SERVICE}"
           break
           ;;
        5) # Tail Journal Log
           additional_info "log"
           show_journal "${NODE_STAT_SERVICE}"
           break
           ;;
        6) # Show Web URL
           echo; echo -e "Web URL (CTRL-Click): \e[1;35mhttps://${LOCAL_IP}:${NODE_STAT_SSL_PORT}\e[0m"
           check_continue
           break
           ;;
        q) # back to main menu
           break 2
           ;;
        *) echo 'Please select an option.' >&2
      esac
      break
    done
  done
}

#-------------------------------------------------------------------------------------------

# START SCRIPT
# Main Menu

# menu loop
while true
do
clear
echo; echo; echo; echo;
echo -e "${G}---------------------------------------------------------"
echo -e "${G}  Full Node Control - Main Menu"
echo -e "${G}---------------------------------------------------------"
echo -e "${NC}Please enter your choice:"
echo -e "${LB}"
options=("     [  1  ]  -=   Bitcoind...      =-$menusep"
         "     [  2  ]  -=   Fulcrum...       =-"
         "     [  3  ]  -=   Mempool...       =-"
         "     [  4  ]  -=   LND...           =-"
         "     [  5  ]  -=   Thunderhub...    =-"
         "     [  6  ]  -=   Glances...       =-"
         "     [  7  ]  -=   Bitfeed...       =-"
         "     [  8  ]  -=   RPC-Explorer...  =-"
         "     [  9  ]  -=   Node Status...   =-"
         "     [  -  ]  -=   ---------------  =-"
         "     [  s  ]  -=   System Info      =-"
         "     [  v  ]  -=   Version Check    =-"
         "     [  -  ]  -=   ---------------  =-"
         "     [  q  ]  -=   Exit the menu    =-")

select reply in "${options[@]}";
do
     echo -e "${NC}" # reset color
     case $REPLY in
         1) # bitcoind menu
            bitcoindmenu
            break
            ;;
         2) # fulcrum menu
            fulcrummenu
            break
            ;;
         3) # mempool menu
            mempoolmenu
            break
            ;;
         4) # lnd menu
            lndmenu
            break
            ;;
         5) # thunderhub menu
            thunderhubmenu
            break
            ;;
         6) # glances menu
            glancesmenu
            break
            ;;
         7) # bitfeed menu
            bitfeedmenu
            break
            ;;
         8) # rpc-explorer menu
            explorermenu
            break
            ;;
         9) # node status menu
            nodestatusmenu
            break
            ;;
         s) # sys info
            sys_info
            break
            ;;
         v) # version check
            check_versions
            break
            ;;
         q) # Exit this script
            clear
            echo; echo;
            echo -e "${NC}" # reset color
            exit
            ;;
         *) echo 'Please select an option.' >&2
     esac
     break
 done
echo; echo;
done

# -------------------------------------------------------------
