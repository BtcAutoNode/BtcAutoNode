## Connect Sparrow Wallet to the Fullnode

[Sparrow Wallet Homepage](https://www.sparrowwallet.com/)  
[Sparrow Wallet on Github](https://github.com/sparrowwallet/sparrow)  
[Read about the advantages using your own node in the Sparrow Wallet Best Practices (on the Docs page)](https://www.sparrowwallet.com/docs/best-practices.html)  

<br>

---

<br>

#### Connect Sparrow Wallet to the newly installed and synced fullnode

- Make sure that bitcoind and fulcrum services are running
- Open the Sparrow Wallet desktop app
- In the top menu go to **'File' --> 'Preferences'** and there go to the **'Server'** tab on the left side
- Enter the following values: 

<kbd><img src="https://github.com/user-attachments/assets/b71fd7dd-b2ba-4acb-85b5-0785275f00d2"></kbd>  
    --> **URL**: enter the IP of the fullnode box (get the IP address via **hostname -I** in a terminal if unknown)  
    --> Leave the rest as shown  
    --> Use the **'Test Connection'** button to check that Sparrow can connect to the node (which will show the server banner like above)  

<br>

If everything worked, then in the lower right corner of the Sparrow Wallet software the tor and blue connection icons should be visible (you might need to click on the toggle button to go online).  
Hovering the mouse over the toggle button will show where Sparrow Wallet is connected to:  

<kbd>![grafik](https://github.com/user-attachments/assets/7a82dc0f-bbe3-44b3-8b08-6b88894ca819)</kbd>

>The Sparrow Wallet software is now connected to the Electrum server of the bitcoin node.  
>Works both for Fulcrum and Electrs with the same settings as show in the screenshot.  

<br>

---

<br>

#### Connect the Sparrow server app (installed via install script):  
(The Sparrow server app might be still useful if someone wants to have a watch-only wallet running on the node.  
Mixing via Whirlpool is not possible anymore for now, so there is maybe no need for the server app at the moment.)  

<kbd><img src="https://github.com/user-attachments/assets/f0400e50-fe8a-4524-93d5-3b8733e6caa4"></kbd>  

<br><br>
