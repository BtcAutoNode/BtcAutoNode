
# BtcAutoNode - Easy Automated Installation of a Bitcoin Full Node and useful Apps via Scripts

<br>

**BtcAutoNode is a set of bash scripts to install/setup a bitcoin full node in a Debian server system (Amd64).**<br>
(Tested so far on Debian 11.7, Debian 12.2 / 12.4, Ubuntu 23.04)<br><br>

Example: Bitcoind installation:

https://github.com/BtcAutoNode/BtcAutoNode/assets/149917291/eb77011b-1f47-447f-af11-735d1a6b4185

<br>
The scripts are based on the Ministry of Nodes Videos and parts from the RaspiBolt Guide.<br><br>

***[Ministry of Nodes Node Box Guide 2022]***<br>
https://www.youtube.com/watch?v=9Kb7TobTNPI&list=PLCRbH-IWlcW2A_kpx2XwAMgT0rcZEZ2Cg<br><br>

***[RaspiBolt Guide]***<br>
https://raspibolt.org/<br><br>

The intention was to make it easier/faster to get a full node up and running (especially for beginners).<br>
This is not a one-click install node package with a fancy Webui (as e.g Umbrel, Raspiblitz,...).<br>

It's more the way of following the videos or Guide and doing everything manually step by step, except that the installation is automated.<br>

Predefined configs and service files are written automatically so that everything fits together.<br>
No service/app is already started after executing the scripts. That should be done by the user.<br>
But each script points out the relevant directories and files at the end of the execution.<br>

It's a good idea to follow the videos and read the guide to understand what is being done and why. But also the scripts are documented and kept simple so that they are easy to follow.<br><br>

**The following individual scripts/applications are currently availabe:**
- System preparation (update, dependencies, user,...)
- ***Bitcoin Core Node*** - Validate Blocks and Transactions
- ***Fulcrum*** - Electrum SPV Server and Indexer
- ***Mempool*** - Visualizer, Explorer and API Service
- ***LND*** - Lightning Network Daemon Node
- ***Thunderhub*** - Lightning Node Manager
- ***Sparrow*** - Server/Terminal (for headless platforms)
- ***Bisq*** - DEX Network (for headless platforms)
- ***Glances*** - An Eye on your System (system monitor)
- 
- ***BTC RPC Explorer*** - Self-Hosted Bitcoin explorer for blockchain and full node
- ***Bitfeed*** - A live visualization of Bitcoin network activity and blockchain explorer
- ***Node Status Monitor*** - A simple php web page showing the status of the apps
- ***Lightning Network Visualizer*** - A graph visualization tool to draw the lightning network
- ***Electrs*** - Electrum Server in Rust (Fulcrum alternative)
<br><br>

## Prerequisites
A working Debian server base system installation is needed with access to the root user (who does the installations).<br>
At least 4GB of Ram should be available, otherwise the mempool build process might fail (and maybe other things).
<br><br>

## Download/Installation
As ***root*** user:<br>
Download the ***install.sh*** installer file which will install git and download/update the repository.<br>
<pre>
wget https://github.com/BtcAutoNode/BtcAutoNode/raw/master/install.sh
chmod +x install.sh
./install.sh
</pre>

## Usage
As ***root*** user:<br>
Cd into the newly created directory ***btcautonode***. Then cd into the ***install*** directory (or upgrade or uninstall).<br>
Execute scripts via ***./<script_name>*** and follow the instructions (Start with the 0_install_system.sh script!).<br>
<pre>
cd btcautonode/install
./0_install_system.sh
./1_install_bitcoind.sh
./2_install_fulcrum.sh
...
</pre>
<pre>
If you want to log the script output into a log file too, execute the scripts like this:
<b>./2_install_fulcrum.sh | tee >(ansi2txt > fulcrum.log)</b> [using ansi2text to strip off color codes]
<b>./2_install_fulcrum.sh | tee fulcrum.log</b> [to keep color codes: view file with: <b>less -R fulcrum.log</b>]
</pre>

## Telegram Group
https://t.me/BtcAutoNode
<br>
