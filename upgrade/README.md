## Upgrade Scripts

The scripts in the **btcautonode/upgrade** folder are used to **upgrade applications** which are already installed.  

<br>

The scripts will check if there is a new version on Github compared to the locally installed version and exits if not.  
>The versions need to be checked thoroughly as it's only a string comprison of the 2 versions (Github and local) and could not be what is wanted!  
>E.g. bitcoin core sometimes releases older version if a newer one (by number) was already released. Or sometimes pre-release-versions are uploaded which you might not want to be installed/upgraded etc...

It also checks if the service of an app is still running and exits if so.  
If both conditions are fullfilled, then the app could be upgraded by pressing the **Enter** key.  

<br>

**Example:**
```
./install.sh                (to update any new data from the Github repository into the btcautonode folder)
cd btcautonode/upgrade      (enter the upgrade scripts folder)
./upgrade_1_bitcoin.sh      (upgrade the bitcoind application with the newer version)
```

<br>

**Example bitcoind upgrade script:**  
![grafik](https://github.com/user-attachments/assets/599d5984-bdb8-41bc-be64-18fc19073b18)  
(See the Asciinema recording below to see a positive case where upgrading is possible)

<br>

**Note:**  
If there is no upgrade script available for an installed application, use the uninstall script to delete everything and then re-install via the install script with the newer version.  

<br>

---

<br>

<details>
<summary><h4>Example Asciinema Recording - view scripts in action (click to elapse or collapse):</h4></summary>
  
[upgrade_1_bitcoin.sh](https://asciinema.org/a/IhKCIAmkEb0OSpdoNwrjtxqlX) (Script runtime: 00:24)
</details>

<br><br>
