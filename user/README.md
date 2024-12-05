
## User Scripts

The scripts in the **btcautonode/user** folder are used by user **satoshi** to help to operate the fullnode.  
They can be called individually or via the node menu (node_menu.sh).  

<br>

#### Download / Installation:  
As user **satoshi** download the scripts to the users home directory (**/home/satoshi**) and make them executable: 
```bash
cd /home/satoshi
wget -O node_menu.sh https://raw.githubusercontent.com/BtcAutoNode/BtcAutoNode/refs/heads/master/user/node_menu.sh
wget -O system_info.sh https://raw.githubusercontent.com/BtcAutoNode/BtcAutoNode/refs/heads/master/user/system_info.sh
wget -O version_check.sh https://raw.githubusercontent.com/BtcAutoNode/BtcAutoNode/refs/heads/master/user/version_check.sh
wget -O mempool_info.sh https://raw.githubusercontent.com/BtcAutoNode/BtcAutoNode/refs/heads/master/user/mempool_info.sh
chmod +x *.sh
```

Then execute via the node menu and respective letter in the menu (m, s, v)...
```bash
./node_menu.sh
```
...or individually:
```bash
./system_info.sh
./version_check.sh
...
```

<br>

---  

<br>

#### node_menu.sh
Bash menu to have it easier to start/stop/restart services, edit config files or view the log of the running application(s).  
This is the entry point for user satoshi to operate the node if one does not want to type every command manually.

**Main menu:**  
![main_menu](https://github.com/user-attachments/assets/4b9c622d-82d8-4176-9f69-b4a6c9befc5f)

**Example sub menu:**  
![sub_menu](https://github.com/user-attachments/assets/bfc19e7e-1197-48e3-aac9-a7714df7920c)

**Note:**  
Log file viewing ( **5** ) might halt with a displayed colon ( **:** ) at the end of the log if there is a lot of new text.  
![grafik](https://github.com/user-attachments/assets/43649f3e-be30-4cc2-9584-c2da448af77d)  
The **down arrow** or **page down** key can be used to scroll down to the latest row.  
To exit log file viewing press **ctrl-c** and then **q** to get back into the menu.  
Config files are opened by the nano text editor (**ctrl-o** to save changes and **ctrl-x** to exit the editor).  

<br>

---  

<br>

#### system_info.sh
Script is used to show basic system monitoring information on one screen. Also running node services will be shown (by their port used).  
<br>
![system_info](https://github.com/user-attachments/assets/a027acc3-c661-4bc2-bc33-0fe0b6e819b9)

<br>

---  

<br>

#### version_check.sh
This script checks latest versions in Github compared to the locally installed node application versions.  
It does not really compare version numbers by which is the biggest number but show differences (e.g. bitcoin core version v27.2 was released after v28.0 was released.  
In this case the script would show that the node is not on the newest version as v27.2 is the latest version uploaded by the developers. And if v28.0 was already installed locally there might not be any need to update even if the script indicates that).  
So discrepancies between versions installed and online are shown which might need to be checked.  
<br>
![version_check](https://github.com/user-attachments/assets/870c6390-4561-47ca-8a73-0e0895377656)

<br>

---  

<br>

#### mempool_info.sh
Script is more a gimmick and shows basic information which can be seen in the mempool app but the info is shown in the terminal.  
It uses the API of the locally installed mempool application to get the values.  
<br>
![mempool_info](https://github.com/user-attachments/assets/288f5a97-daf0-40fb-9694-12df490573ab)

<br>

---  

<br>

<details>
<summary><h4>Asciinema Recordings - view scripts in action (click to elapse or collapse):<h4></summary>
  
[node_menu.sh](https://asciinema.org/a/DJxRT9uLmTAcSHYG8X96ELhjI) (Script runtime: 02:58)

[system.info.sh](https://asciinema.org/a/xxQ33Gj8z9ncvKgBA5fUX3HUn) (Script runtime: 00:17)

[version_check.sh](https://asciinema.org/a/MLaDvbQHGk5DiHxbO0wTWGlPj) (Script runtime: 00:23)

[mempool_info.sh](https://asciinema.org/a/UsghrtPg6z487FQIAcAt7OTR7) (Script runtime: 00:22)
</details>

<br><br>
