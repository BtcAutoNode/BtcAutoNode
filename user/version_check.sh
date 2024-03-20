#!/bin/bash

########################################
# Github Versions vs installed Versions
########################################


#-----------------------------------------------------------------
# source/read config from repository
. <(curl -sL https://github.com/BtcAutoNode/BtcAutoNode/raw/master/CONFIG)
# or if you changed anything the config, copy CONFIG to here and comment out above line and uncomment the next line
#. CONFIG
#-----------------------------------------------------------------


clear
echo
echo -e "${Y}-------------------------------------------------${NC}"
echo -e "${LG}Latest versions on Github vs Installed Versions:${NC}"
echo -e "${Y}-------------------------------------------------${NC}"
echo

BITCOIN_NAM="Bitcoin Core"
BITCOIN_GIT=$(curl -sL https://github.com/bitcoin/bitcoin/releases/latest | grep "<title>Release" | cut -d ' ' -f 6)
BITCOIN_LOC=$(bitcoin-cli --version 2>/dev/null | grep version | cut -d ' ' -f 6 | cut -c2-5)

FULCRUM_NAM="Fulcrum"
FULCRUM_GIT=$(curl -sL https://github.com/cculianu/Fulcrum/releases/latest | grep "<title>Release" | cut -d ' ' -f 5)
FULCRUM_LOC=$("${FULCRUM_DIR}"/Fulcrum --version 2>/dev/null | grep Release | cut -d ' ' -f 2)

MEMPOOL_NAM="Mempool"
MEMPOOL_GIT=$(curl -sL https://api.github.com/repos/mempool/mempool/releases/latest | grep tag_name | head -1 | cut -d '"' -f4 | cut -c2-)
MEMPOOL_LOC=$(cat "${MEMPOOL_BACKEND_DIR}"/package.json 2>/dev/null | jq -r ".version")

LND_NAM="LND"
LND_GIT=$(curl -sL https://github.com/lightningnetwork/lnd/releases/latest | grep "<title>Release" | cut -d ' ' -f 5 | cut -c2-)
LND_LOC=$(lncli --version 2>/dev/null | cut -d ' ' -f 3)

THH_NAM="Thunderhub"
THH_GIT=$(curl -sL https://github.com/apotdevin/thunderhub/releases/latest | grep "<title>Release" | cut -d ' ' -f 4 | cut -c2-)
THH_LOC=$(cat "${THH_DIR}"/package.json 2>/dev/null | jq -r ".version")

SPARROW_NAM="Sparrow Server"
SPARROW_GIT=$(curl -sL https://github.com/sparrowwallet/sparrow/releases/latest | grep "<title>Release" | cut -d ' ' -f 4)
SPARROW_LOC=$(Sparrow --version 2>/dev/null | cut -d ' ' -f 3)

BISQ_NAM="Bisq"
BISQ_GIT=$(curl -sL https://github.com/bisq-network/bisq/releases/latest | grep "<title>Release" | cut -d ' ' -f 4 | cut -c2-)
BISQ_LOC=$("${BISQ_APP_DIR}"/desktop/build/app/bin/desktop --help 2>/dev/null | grep -e "Bisq Desktop version" | cut -d ' ' -f 4)

GLANCES_NAM="Glances"
# latest release
###GLANCES_GIT=$(curl -sL https://github.com/nicolargo/glances/releases/latest | grep "<title>Release" | cut -d ' ' -f 5)
# install script installs latest tag, not release.
# latest tag
GLANCES_GIT=$(curl -sL "https://api.github.com/repos/nicolargo/glances/tags" | jq -r '.[0].name' | cut -c2-)
GLANCES_LOC=$(glances --version 2>/dev/null | grep Glances | cut -d' ' -f 2 | cut -c2-)

RPCEX_NAM="BTC-RPC-Explorer"
RPCEX_GIT=$(curl -sL https://github.com/janoside/btc-rpc-explorer/releases/latest | grep "<title>Release" | cut -d ' ' -f 4 | cut -c2-)
RPCEX_LOC=$(cat "${EXPLORER_DIR}"/package.json 2>/dev/null | jq -r ".version")

BITFEED_NAM="Bitfeed"
BITFEED_GIT=$(curl -sL https://github.com/bitfeed-project/bitfeed/releases/latest | grep "<title>Release" | cut -d ' ' -f 5 | cut -c2-)
BITFEED_LOC=$(cat "$BITFEED_FRONTEND_DIR"/package.json 2>/dev/null | jq -r ".version")

LNVIS_NAM="LN-Visualizer"
LNVIS_GIT=$(curl -sL https://github.com/MaxKotlan/LN-Visualizer/releases/latest | grep "<title>Release" | cut -d ' ' -f 4 | cut -c2-)
LNVIS_LOC=$(cat "$LNVIS_DIR"/package.json 2>/dev/null | jq -r ".version")


NAMS=("$BITCOIN_NAM" "$FULCRUM_NAM" "$MEMPOOL_NAM" "$LND_NAM" "$THH_NAM" "$SPARROW_NAM" "$BISQ_NAM" "$GLANCES_NAM" "$RPCEX_NAM" "$BITFEED_NAM" "$LNVIS_NAM")
GITS=("$BITCOIN_GIT" "$FULCRUM_GIT" "$MEMPOOL_GIT" "$LND_GIT" "$THH_GIT" "$SPARROW_GIT" "$BISQ_GIT" "$GLANCES_GIT" "$RPCEX_GIT" "$BITFEED_GIT" "$LNVIS_GIT")
LOCS=("$BITCOIN_LOC" "$FULCRUM_LOC" "$MEMPOOL_LOC" "$LND_LOC" "$THH_LOC" "$SPARROW_LOC" "$BISQ_LOC" "$GLANCES_LOC" "$RPCEX_LOC" "$BITFEED_LOC" "$LNVIS_LOC")

# loop over arrays and print version info
len=${#NAMS[@]}
for(( i=0; i<$len; i++ ))
do
   printf " %b${NAMS[i]}%b:\n" "${LB}" "${NC}"
   if [ "${GITS[i]}" = "${LOCS[i]}" ]; then clr="${G}"; else clr="${R}"; fi
   printf "   %7s [%b]\n" "Github" "${clr}${GITS[i]}${NC}"
   printf "   %7s [%b]\n" "Install" "${clr}${LOCS[i]}${NC}"
   echo
done

echo -e "${Y}-------------------------------------------------${NC}"
echo
