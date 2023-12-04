<?php
$configs = parse_ini_file("config.ini");
date_default_timezone_set($configs['timezone']);
?>

<html>
    <head>
        <title>Node Server Status Monitor</title>
        <link href="core_style.css" rel="stylesheet"/>
        <?php
        if ($configs['theme_css'] != "none") {
            echo '<link href="' . $configs['theme_css'] . '" rel="stylesheet" />';
        }
        ?>
        <link href='http://fonts.googleapis.com/css?family=Lato:100,300' rel='stylesheet' type='text/css'>
    </head>
    <body>

        <h1>Node Server Status Monitor</h1>

        <div id="statusArea"></div>

        <footer class="foot">Refresh page? <input type="checkbox" name="refreshEnable" id="refreshEnable"> |
          Refresh in: <span id="refreshTime">0</span> seconds
        </footer>

        <script type="text/javascript" src="https://code.jquery.com/jquery-2.1.4.min.js"></script>
        <script type="text/javascript">
            var refreshChk = document.getElementById("refreshEnable");
            refreshChk.checked = true;
            var pageTime = document.getElementById("refreshTime");
            var timeConst = <?php echo $configs['refreshtime'] ?>;
            var time = timeConst;
            pageTime.innerHTML = time.toString();

            function ajaxRefresh() {
                $.ajax({
                    url: 'refresh.php',
                    type: 'POST',
                    data: {
                      refresh: "TRUE"
                    },
                    success: function(response) {
                      $("#statusArea").html(response);
                    }
                });
            }

            ajaxRefresh();

            function decrease() {
              time = time - 1;
              pageTime.innerHTML = time.toString();
              if (time == 0) {
                //location.reload();
                ajaxRefresh();
                time = timeConst + 1; // My OCD likes to see the value I want before it is decreased, remove the "+ 1" if you want
              }
            }

            var timer = window.setInterval(decrease, 1000); // starts a timer

            // has the refresh checkbox been changed?
            $('input[name = refreshEnable]').change(function(){
              // checked
              if($(this).is(':checked'))
              {
                // starts the timer
                timer = window.setInterval(decrease, 1000);
              // not checked
              } else {
                // stop the timer
                clearInterval(timer);
              }

            });

        </script>
    </body>
</html>
