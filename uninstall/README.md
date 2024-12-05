## Uninstall Scripts

The scripts in the **btcautonode/uninstall** folder are used to **delete all files and folders** created by an install script for any app.  

<br>

The uninstall scripts will also stop the app's service(s) before deletion.  
<br>
System packages installed by the 0_install_system.sh script will not be removed (as they might be used by other scripts as well)...but packages only used for a specific installation (like Bitfeed) will be also removed.

<br>

**Caution!**
>Be aware that files, configurations, or folders created or changed by you will also just be deleted!   
>If you manually changed anything you might want to keep, then make sure to backup these files before executing the uninstall script for the specific application!

<br>

**Note:**  
If there is no upgrade script available for an application, use the uninstall script to delete everything and then use the install script again to re-install the new version after updating the btcautonode folder from the repository (by executing the install.sh script).

<br>

**Example:**
```bash
./install.sh 					(to update any new data from the Github repository into the btcautonode folder)
cd btcautonode/uninstall		(enter the uninstall scripts folder)
./uninstall_electrs.sh			(uninstall all files/folders of the installed electrs app)
cd ../install					(enter the install scripts folder)
./install_electrs.sh			(re-install the electrs app with the new version in the updated config)
```

<br>

---

<br>

<details>
<summary><h4>Asciinema Recordings - view scripts in action (click to elapse or collapse):</h4></summary>
[uninstall_1_bitcoind.sh](https://asciinema.org/a/3ezewSeAnqhaxZEYA1qS8s4yS) (Script runtime: 00:24)

[uninstall_2_fulcrum.sh](https://asciinema.org/a/Xyk1oemh266vJgaiAoZa1ZLLw) (Script runtime: 00:22)

[uninstall_3_mempool.sh](https://asciinema.org/a/1UWn0SDpeV3Yszwg1oAZohQV5) (Script runtime: 00:27)

[uninstall_4_lnd.sh](https://asciinema.org/a/btkgiyqAPzHVvGiK2WPUFVCzn) (Script runtime: 00:21)

[uninstall_5_thunderhub.sh](https://asciinema.org/a/Mbcwt5Q4yq7l3fki3W3PrRi6e) (Script runtime: 00:22)

[uninstall_6_sparrow.sh](https://asciinema.org/a/d3q22m2dpSsKps0wUzNApgIHV) (Script runtime: 00:19)

[uninstall_7_bisq.sh](https://asciinema.org/a/rXdFpWUVnkjCW3DOYlOO3ymCD) (Script runtime: 01:39)

[uninstall_8_glances.sh](https://asciinema.org/a/X1dsRi06QitBz5PSXAeFkWoli) (Script runtime: 00:29)

[uninstall_bitfeed.sh](https://asciinema.org/a/PrmGGhugQm3v3tDe1nJXfcasW) (Script runtime: 00:35)

[uninstall_btcpay_server.sh](https://asciinema.org/a/EtBWisCqH3HDkxo3DFyaMuD2J) (Script runtime: 00:40)

[uninstall_btc-rpc-explorer.sh](https://asciinema.org/a/yKYuEmalcjjiSxGpnPfzggnIu) (Script runtime: 00:22)

[uninstall_joinmarket_jam.sh](https://asciinema.org/a/1ywsY9Er61wh2MqCzpjDEq9ZW) (Script runtime: 00:57)

[uninstall_ln-visualizer.sh](https://asciinema.org/a/MPn6a27sHx0twDLPyL3rGKR4r) (Script runtime: 00:26)

[uninstall_node_status.sh](https://asciinema.org/a/HsKMJJpJ0cKHGQpFyeACQD9Hz) (Script runtime: 00:32)

[uninstall_rtl.sh](https://asciinema.org/a/NQ7Rdj5C09uZxXVjOqx1D5S1p) (Script runtime: 00:22)

[uninstall_electrs.sh](https://asciinema.org/a/nFaNK0wDpmWnZa6J4gz51LsgP) (Script runtime: 00:28)
</details>

<br><br>
