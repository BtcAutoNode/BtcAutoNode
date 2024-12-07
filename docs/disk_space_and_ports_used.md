## Disk Space Requirements

This is a measurement of the disk space used after installation of all applications as an indication what might be needed:  
<br>


| Install Script|   KByte   |   Space   |    Sum    |
|---------------|-----------|-----------|-----------|
| debian 11.8   |   585408  |  (0,58G)  |  (0,58G)  |
| install.sh    |   717772  |  (0,14G)  |  (0,72G)  |
| 0_system      |  1687592  |  (0,97G)  |  (1,69G)  |
| 1_bitcoin     |  1937576  |  (0,25G)  |  (1,94G)  |
| 2_fulcrum     |  1980912  |  (0,04G)  |  (1,98G)  |
| 3_mempool     |  3322172  |  (1,34G)  |  (3,32G)  |
| 4_lnd         |  3518144  |  (0,20G)  |  (3.52G)  |
| 5_thunderhub  |  4619016  |  (1,10G)  |  (4,62G)  |
| 6_sparrow     |  4855164  |  (0,24G)  |  (4,86G)  |
| 7_bisq        | 10555844  |  (5,70G)  | (10,56G)  |
| 8_glances     | 10752900  |  (0,19G)  | (10,75G)  |
| bitfeed       | 10975108  |  (0,23G)  | (10,98G)  |
| explorer      | 11180768  |  (0,20G)  | (11,18G)  |
| node_status   | 11204788  |  (0,02G)  | (11,20G)  |
| ln-visualizer | 12389108  |  (1,19G)  | (12,39G)  |
| rtl           | 12889856  |  (0,50G)  | (12,89G)  |
| electrs       | 14139336  |  (1,25G)  | (14,14G)  |
| joinmarket    | 14867464  |  (0,73G)  | (14,87G)  |
| btcpayserver  | 16087376  |  (1.22G)  | (16,09G)  |

<br>

## Big Data directories (as of December 06th, 2024):

The size of the 'big-data' folders (bitcoin blockchain and index, fulcrum or electrs indexes):  

<br>

**Bitcoin Data:**  
<pre>
 blocks:        658 GB  
 chainstate:     12 GB  
 indexes:        65 GB  
</pre>

**Fulcrum Data:**  
<pre>
 fulcrum_db:    157 GB  
</pre>

**Electrs Data:**  
<pre>
 electrs_db:     50 GB  
</pre>

<br>

## Ports Used

This is a list of ports defined in the configs of each application (opened or used):  
<br>
#### system script:
opens:  
<pre>
tor control port:          9051  
tor proxy port:            9050  
</pre>

#### bitcoind:
opens:  
<pre>
bitcoin rpc port:          8332
zmqpubrawblock:            28332
zmqpubrawtx=tcp:           28333
zmqpubhashblock:           8433
zmqpubhashblock:           28334
zmqpubsequence:            28335
</pre>

uses:  
<pre>
tor proxy port:            9050
</pre>

#### fulcrum:
opens:  
<pre>
fulcrum tcp:               50001
fulcrum ssl:               50002
fulcrum admin:             8000   (commented out in config)
fulcrum stats:             8090   (commented out in config)
</pre>

uses:  
<pre>
bitcoin rpc port:          8332
</pre>

#### mempool:
opens:  
<pre>
mempool http port:         8999
mempool web ssl:           4080
</pre>

uses:  
<pre>
bitcoin rpc port:          8332
fulcrum ssl port:          50002 
maria-db port:             3306
tor proxy port:            9050
</pre>

#### lnd:
opens:  
<pre>
lnd listen port:           9735
rpc listen port:           10009
rest listen port:          8080
</pre>

uses:  
<pre>
bitcoin rpc port:          8332
bitcoin zmqpubrawblock:    28332
bitcoin zmqpubrawtx:       28333
</pre>

#### thunderhub:
opens:  
<pre>
thh app server port:       3000
thh web ssl port:          4001
</pre>

uses:  
<pre>
tor proxy port:            9050
lnd rpc listen port:       10009 
</pre>

#### sparrow:
uses:  
<pre>
fulcrum ssl port:          50002
tor proxy port:            9050
</pre>

#### bisq:
opens:  
<pre>
bisq xpra tcp/ssl port:    9876
</pre>

#### glances:
opens:  
<pre>
glances server port:       61208
glances web ssl port:      4002
</pre>

#### node status:
opens:  
<pre>
node_status web ssl port:  4021
</pre>

#### btc-rpc-explorer:
opens:  
<pre>
explorer app port:         3002
explorer web ssl port:     4032
</pre>

uses:  
<pre>
bitcoin rpc port:          8332
fulcrum ssl port:          50002
</pre>

#### bitfeed:
opens:  
<pre>
bitfeed app port:          9999
bitfeed web ssl port:      4041
</pre>

#### ln-visualizer:
opens:  
<pre>
lnvis app port:            5647
lnvis web ssl port:        4070
</pre>

used:  
<pre>
lnd rpc listen port:       0009
</pre>

#### ride the lightning:
opens:  
<pre>
rtl app port:              3010
rtl web ssl port:          4010
</pre>

#### joinmarket + jam:
opens:  
<pre>
joinmarket daemon:         27183   
jam app port:              3020
jam web ssl port:          4020
</pre>

#### btcpayserver (and nbxplorer):
NBXplorer:
BTCPay Server:

<br><br>
