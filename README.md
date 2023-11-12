# BtcAutoNode - Automated installation of a Bitcoin Full Node
<br>

**BtcAutoNode is a set of bash scripts to install/setup a bitcoin full node in a Debian server system (Amd64).**<br>
(Tested so far on Debian 11.7, Debian 12.2, Ubuntu 23.04)<br><br>

The scripts are based on the Ministry of Nodes Videos and parts from the RaspiBolt Guide.<br><br>
**[Ministry of Nodes Node Box Guide 2022]**<br>
https://www.youtube.com/watch?v=9Kb7TobTNPI&list=PLCRbH-IWlcW2A_kpx2XwAMgT0rcZEZ2Cg<br><br>
**[RaspiBolt Guide]**<br>
https://raspibolt.org/<br><br>

The intention was to make it easier/faster to get a full node up and running (especially for beginners).<br>
This is not a one-click install node package with a fancy Webui (as e.g Umbrel, Raspiblitz,...).<br>

It's more the way of following the videos or Guide and doing everything manually step by step, except that the installation is automated.<br>

Predefined configs and service files are written automatically so that everything fits together.<br>
No service/app is already started after executing the scripts. That should be done by the user.<br>
But each script points out important directories and files at the end of the execution.<br>

It's a good idea to follow the videos and read the guide to understand what is being done and why. But also the scripts are documented and kept simple so that they are easy to follow.<br><br>

**The following scripts/applications are currently availabe:**
- System preparation (update, dependencies, user,...)
- Bitcoind
- Fulcrum
- Mempool
- Lightning Lnd
- Thunderbird (for managing Lnd)
- Sparrow Terminal/Server
- Bisq (headless)
<br><br>

## Prerequisites
A working Debian server base system installation is needed with access to the root user (who does the installations).<br>
At least 4GB of Ram should be available, otherwise the mempool build process might fail (and maybe other things).
<br><br>

## Download/Installation
Download the install.sh installer file which will install git and download/update the repository.<br>
<pre>
wget https://raw.githubusercontent.com/BtcAutoNode/BtcAutoNode/master/install.sh
chmod +x install.sh
./install.sh
</pre>

## Usage
Cd into the newly created directory ***BtcAutoNode***. Then cd into the ***install*** directory.<br>
Execute scripts via ***./<script_name>*** and follow the instructions.<br>
<pre>
cd BtcAutoNode/install
./0_install_system.sh
...
</pre>

## Telegram Group
https://t.me/BtcAutoNode
<br>
