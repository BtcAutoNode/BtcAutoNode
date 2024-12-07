## Enable the Lightning Dashboard in Mempool

<br>
If LND is used, then the lightning dashboard in mempool can be enabled.  

![mempool_lnd](https://github.com/user-attachments/assets/1ee336e0-eb84-418f-b5e6-435c3b46c5ac)

It can be accessed by the Lightning button in the mempool menu:  
![mempool_lnd_menu](https://github.com/user-attachments/assets/2cb6a300-3152-4468-aa63-3b5852851c01)

<br>

---

<br>

#### Stop the Mempool Service
```
systemctl stop mempool.service 		(or via node_menu script)
``` 
<br>

#### Mempool Backend Changes:
As user **satoshi**:
- Open the mempool backend config **mempool-config.json** in **/home/satoshi/mempool/backend**:  
  ```
  cd /home/satoshi/mempool/backend
  nano mempool-config.json
  ```
- Change the following values to **true**:  
  ```
  LIGHTNING  -->	ENABLED : true
  MAXMIND    -->	ENABLED : true
  ```
  ![mempool_lnd_backend_conf](https://github.com/user-attachments/assets/006f22f8-7de8-4d2c-9d3d-dedb7b6c41be)
  
- Rebuild the mempool backend application:  
  ```
  npm run build
  ```
<br>

#### Mempool Frontend Changes:
As user **satoshi**:  
- Copy the mempool frontend config from the sample config:  
  ```
  cd /home/satoshi/mempool/frontend
  cp mempool-frontend-config.sample.json mempool-frontend-config.json
  ```
- Change the following value to **true**:  
  ```
  LIGHTNING : true
  ```
  ![mempool_lnd_frontend_conf](https://github.com/user-attachments/assets/57d4849d-34f4-4641-91b4-ceb0cb29f137)

- Rebuild the mempool frontend application (the new build is in the **dist** directory):  
  ```
  npm run build
  ```
  
As user **root**:  
- Delete the old mempool folder in the Nginx web server webroot directory:  
  ```
  rm -rf /var/www/html/mempool
  ```
- Move the newly build frontend web application to the webroot dir:  
  ```
  mv /home/satoshi/mempool/frontend/dist/mempool /var/www/html/mempool
  ```
- Change ownership of the frontend web directoy just moved (to user www-data):  
  ```
  chown -R www-data:www-data /var/www/html/mempool
  ```
- Restart the NGinx web server:  
  ```
  restart nginx: systemctl restart nginx
  ```
<br>

#### Restart the Mempool Service
```
systemctl start mempool.service 		(or via node_menu script)
```
<br>

>Make sure that the LND service is also running!

It takes some time after re-starting the mempool service to process and index the needed data.  
After some time the Mempool Lightning button will be visible after doing a refresh in the browser.  
After much more time all data in the Lightning dashboard is available (as in the above screenshot).
>Note:  
>It really needs time, maybe some hours!

<br><br>
