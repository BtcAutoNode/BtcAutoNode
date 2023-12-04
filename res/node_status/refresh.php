<?php
$configs = parse_ini_file("config.ini");
date_default_timezone_set($configs['timezone']);
$services = explode(",", $configs['services']);
$apps = explode(",", $configs['apps']);

$servicestatus = array();
$appstatus = array();
$uptime = array();

for ($i = 0; $i <= count($services) - 1; $i++) { // Grabs all the status' of all the services listed in the array
    $temp = shell_exec("service " . strtolower($services[$i]) . " status");

    if (strpos($temp, 'Loaded: loaded') !== false) {
      if (strpos($temp, 'Active: active') !== false) {
            // Service running
            $servicesstatus[$i] = "Running";
        } elseif (strpos($temp, 'Active: inactive') !== false) {
            // Service halted
            $servicesstatus[$i] = "Halted";
        } elseif (strpos($temp, 'Active: failed') !== false) {
           // Service failed
            $servicesstatus[$i] = "Failed";
        } else {
            // Unrecognised response...
            $servicesstatus[$i] = "Unknown";
        }
    } else {
        // Unrecognised response... (from status call) - is the service an installed program?
        $servicesstatus[$i] = "No Service?";
    }
} //for


for ($i = 0; $i <= count($apps) - 1; $i++) { // Grabs all the status' of all the apps listed in the array
    $temp_ps = shell_exec("pgrep -l -i " . $apps[$i]);
    $temp_which = shell_exec("whereis " . $apps[$i] . " | cut -d ':' -f2");
    $temp_which_len = strlen( $temp_which );

    if ( $temp_which_len > 1 ) {
        if (!empty($temp_ps)) {
            // Service running
            $appstatus[$i] = "Running";
        } elseif (empty($temp_ps)) {
            // Service halted
            $appstatus[$i] = "Halted";
        } else {
            // Unrecognised response... (from service status)
            $appstatus[$i] = "Unknown";
        }
    } else {
        // Unrecognised response... (from status call) - is the service an installed program?
        $appstatus[$i] = "No App?";
    }
} // for


// Get Uptime Info
$temp = shell_exec("uptime");
$temp = str_replace(",", "", $temp);
$uptimeExplode = explode(" ", $temp);

$uptime[2] = $uptimeExplode[count($uptimeExplode) - 3]; // Set 1 min average.
$uptime[3] = $uptimeExplode[count($uptimeExplode) - 2]; // Set 5 min average.
$uptime[4] = $uptimeExplode[count($uptimeExplode) - 1]; // Set 15 min average.

if (array_search("user", $uptimeExplode) == FALSE) {
    $i = array_search("users", $uptimeExplode);
} else {
    $i = array_search("user", $uptimeExplode);
}
$uptime[0] = $uptimeExplode[$i - 1]; // Set number of active users.

$i = array_search("up", $uptimeExplode);
$uptime[1] = $uptimeExplode[$i + 1] . " " . $uptimeExplode[$i + 2]; // Set uptime.

?>
<p class="foot" align="center">Applications with Systemd Service</p>
<table class="services">
    <tr>
        <?php
        for ($i = 0; $i <= count($services) - 1; $i++) {
            if ( $i == $configs['wrap'] ) { echo "</tr><tr>"; }
            echo '<td><div class="circle" ';
            if ($servicesstatus[$i] == "Running") {
                echo ' style="border: 3px solid #00FF00;"';
            } elseif ($servicesstatus[$i] == "Halted") {
                echo ' style="border: 3px solid #FF0000;"';
            } elseif ($servicesstatus[$i] == "Failed") {
                echo ' style="border: 3px solid #FF0000;"';
            } else {
                echo ' style="border: 3px solid #FFDE00;"';
            }
            echo "><h4>" . $services[$i] . "</h4><h2";
            if ($servicesstatus[$i] == "Running") {
                echo ' style="color: #00FF00;"';
            } elseif ($servicesstatus[$i] == "Halted") {
                echo ' style="color: #FF0000;"';
            } elseif ($servicesstatus[$i] == "Failed") {
                echo ' style="color: #FF0000;"';
            } else {
                echo ' style="color: #FFDE00;"';
            }
            echo ">" . $servicesstatus[$i] . "</h2></div></td>";
        }
        ?>
    </tr>
</table>
<p class="foot" align="center">Applications without Systemd Service</p>
<table class="apps">
    <tr>
        <?php
        for ($i = 0; $i <= count($apps) - 1; $i++) {
            if ( $i == $configs['wrap'] ) { echo "</tr><tr>"; }
            echo '<td><div class="circle" ';
            if ($appstatus[$i] == "Running") {
                echo ' style="border: 3px solid #00FF00;"';
            } elseif ($appstatus[$i] == "Halted") {
                echo ' style="border: 3px solid #FF0000;"';
            } else {
                echo ' style="border: 3px solid #FFDE00;"';
            }
            echo "><h4>" . $apps[$i] . "</h4><h2";
            if ($appstatus[$i] == "Running") {
                echo ' style="color: #00FF00;"';
            } elseif ($appstatus[$i] == "Halted") {
                echo ' style="color: #FF0000;"';
            } else {
                echo ' style="color: #FFDE00;"';
            }
            echo ">" . $appstatus[$i] . "</h2></div></td>";
        }
        ?>
    </tr>
</table>

<div class="foot">
    Last update: <?php echo date('H:i:s'); echo " (" . $configs['timezone'] . ")" ?> |
    <?php
    if ($configs['activeusers'] == 1) {
/*      Active Users: <?php echo $uptime[0]; ?> | */
      echo " Active Users: " . $uptime[0] . " |";
    }
    ?>
    Uptime: <?php echo $uptime[1]; ?>
    <?php
    if ($configs['load1'] == 1) {
        echo " | Load (1 min): " . $uptime[2];
    }
    if ($configs['load5'] == 1) {
        echo " | Load (5 min): " . $uptime[3];
    }
    if ($configs['load15'] == 1) {
        echo " | Load (15 min): " . $uptime[4];
    }
    ?>
</div>
