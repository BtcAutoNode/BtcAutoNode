## Use an External SSD for the Big Data

If there is no big disk installed in the nodebox where all the big data (blockchain, indexes etc) can be stored, an external usb disk can also be used.  
So the system itself and node services are installed on the internal smaller disk as normal but the directories containing the big data will be outsourced to the usb disk and linked to the places where they are needed.  

[Guide - partition and format a disk to the ext4 filesystem](https://www.digitalocean.com/community/tutorials/how-to-partition-and-format-storage-devices-in-linux#create-the-new-partition)  

<br>

---

<br>

### Preparing the disk
As user **root**:
- Create partition on the external usb disk and format to the ext4 file system   
  >see the guide above or use a graphical linux app like GParted  

- On the nodebox create a directory to later mount the external usb disk into:
  >Change 'nodedata' if you want. But note that it's used several times below you need to also change!
  ```
  mkdir /media/nodedata  
  ```
  ![grafik](https://github.com/user-attachments/assets/58ecfdf5-ffe1-4519-8396-7e3bb9522c28)
- Connect the external usb disk to the nodebox machine  
- List all disks and partitions  
  >We look for a partition like /dev/sda1 or /dev/sdb1 in the output  
  >Check sizes of the disks/partitions to get the right one (the external usb disk)  
  >If unsure, unplug the disk, execute the command again to see what is there. Plugin the usb disk, execute again and check what's changed  
  ```
  lsblk -p | grep disk
  ```
  ![grafik](https://github.com/user-attachments/assets/15c1818c-8e37-4a9d-9bd5-f87890bc232a)

- Get the UUID of the partition (from the UUID column - here: 5013d90d-29f1-4584-a6f4-3b0468b3d6f0):  
  ```
  lsblk -f
  ```
  ![grafik](https://github.com/user-attachments/assets/937f2208-81bf-4480-8afd-f051e7fb66a1)
  
- Open **/etc/fstab** with the e.g. nano editor to enter mount information for the external usb disk...  
  >It will then automount on next reboot and can be easily mounted via **mount -av** when needed  
  ```
  nano /etc/fstab 
  ```
- ...and create a new row for the external usb disk using the disks UUID:  
  ```
  UUID=<your_disks_uuid>  /media/nodedata   ext4   defaults,noatime,nofail 0 0
  ```
  ![grafik](https://github.com/user-attachments/assets/129b4493-295f-47d7-994e-22313ea3b560)  
- Save and exit the file via **ctrl-o** and **ctrl-x**
  
- Mount the external usb disk into the previously created folder:  
  ```
  mount -av  
  ```
  ![grafik](https://github.com/user-attachments/assets/a6ec7aba-c66d-4cec-a500-5f26cef49165)  
  
- Create the 4 folders to keep the big data (3 for bitcoind and 1 for fulcrum/or electrs):  
  ```
  cd /media/nodedata
  mkdir blocks
  mkdir chainstate
  mkdir indexes
  mkdir fulcrum_db (or if electrs will be used: mkdir electrs_db)
  ```  
- Change the ownership of /media/nodedata and sub directories to user **satoshi**:  
  ```
  chown -R satoshi:satoshi /media/nodedata
  ```
  Should now be looking like this (fulcrum_db or electrs_db, not both!):  
  ![grafik](https://github.com/user-attachments/assets/ae04aef2-9e96-419a-8445-444498ab307b)

<br>

---

<br>

### Installing the programs (if not already installed before)
#### bitcoind:
As user **root**:  
- Execute the btcautonode system and bitcoind install scripts (if not done already before):  
  ```
  ./0_install_system.sh script

  ./1_install_bitcoind.sh script (do not start the bitcoind service yet!)
  ```

As user **satoshi**:
- Create symbolic links to the 3 bitcoin folders on the external usb disk in /home/satoshi/.bitcoin:  
  ```
  ln -s /media/nodedata/indexes /home/satoshi/.bitcoin/indexes
  ln -s /media/nodedata/chainstate /home/satoshi/.bitcoin/chainstate
  ln -s /media/nodedata/blocks /home/satoshi/.bitcoin/blocks
  ```
  ![grafik](https://github.com/user-attachments/assets/00d89868-1a4e-4fe4-9c66-4edf6be487ba)  
  
#### fulcrum:
As user **root**:  
- Execute the btcautonode fulcrum install script (if not done already before):
  ```
  ./2_install_fulcrum.sh script (do not start the fulcrum service yet!)
  ```
- Delete fulcrum_db dir if it exists in /home/satoshi (should be empty):  
  ```
  rmdir /home/satoshi/fulcrum_db
  ```
- Create symbolic link to the fulcrum_db folder on the external disk into /home/satoshi:  
  ```
  ln -s /media/nodedata/fulcrum_db /home/satoshi/fulcrum_db
  ```
  ![grafik](https://github.com/user-attachments/assets/aa934e79-4b55-4ebf-a4cd-97e7ef45deb1)  

#### or electrs (instead of fulcrum):
As user **root**:
- Execute the btcautonode electrs install script (if not done already before):
  ```
  ./install_electrs.sh script (do not start the electrs service!)
  ```
- Delete electrs_db dir if it exists (should be empty):  
  ```
  rmdir /home/satoshi/electrs_db
  ```
- Create symbolic link to the electrs_db folder on the external disk into /home/satoshi:  
  ```
  ln -s /media/nodedata/electrs_db /home/satoshi/electrs_db
  ```
  ![grafik](https://github.com/user-attachments/assets/6dd6be6a-0cd5-430a-bcfd-9e1185bbab03)  
  
<br>

---

<br>

### Starting the systemd services
#### bitcoind:
As user **satoshi**:  
- The bitcoind service can now be started to sync the blockchain:
  (bitcoind will use the directories blocks, chainstate, indexes in /home/satoshi/.bitcoin which link to the external usb disk folders):  
  ```
  sudo systemctl start bitcoind.service
  ```
- Check in /media/nodedata that the directory size is growing:  
  ```
  du -h /media/nodedata
  ```
- Wait until the blockchain is fully synced (100%). Check /home/satoshi/.bitcoin/debug.log for the log (exit with 'q'):  
  ```
  tail -f /home/satoshi/.bitcoin/debug.log
  ```
  
#### fulcrum:
As user **satoshi**:
- If the Bitcoin blockchain is fully synced, start the fulcrum service to sync the fulcrum indexes
  (fulcrum will use the dir fulcrum_db in /home/satoshi/ which links to the external usb disk folder)
  ```
  sudo systemctl start fulcrum.service
  ```
  
#### or electrs (instead of fulcrum)
As user **satoshi**:
- If the Bitcoin blockchain is fully synced, start the electrs service to sync the electrs indexes
  (electrs will use the dir electrs_db in /home/satoshi/ which links to the external usb disk folder)
  ```
  sudo systemctl start electrs.service
  ```
  
<br>

---

<br>

### Unplug the external usb disk
To unplug the external usb disk, stop the services, unmount the disk and then unplug the disk.
As user **root**:
```
systemctl stop fulcrum.service (or if electrs is used: systemctl stop electrs.service)
systemctl stop bitcoind.service
	(optional: systemctl status fulcrum.service (to check if the service is stopped))
	(optional: systemctl status bitcoind.service (to check if the service is stopped))
umount /media/nodedata
```

<br><br>
