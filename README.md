monero-cryptonote-pool
======================

High performance Node.js (with native C addons) mining pool for CryptoNote based coins. ( Monero )



#### Table of Contents
* [Features](#features)
* [Community Support](#community--support)
* [Pools Using This Software](#pools-using-this-software)
* [Usage](#usage)
  * [Requirements](#requirements)
  * [Downloading & Installing](#1-downloading--installing)
  * [Configuration](#2-configuration)
  * [Configure Easyminer](#3-optional-configure-cryptonote-easy-miner-for-your-pool)
  * [Starting the Pool](#4-start-the-pool)
  * [Host the front-end](#5-host-the-front-end)
  * [Customizing your website](#6-customize-your-website)
  * [Upgrading](#upgrading)
* [JSON-RPC Commands from CLI](#json-rpc-commands-from-cli)
* [Monitoring Your Pool](#monitoring-your-pool)
* [Donations](#donations)
* [Credits](#credits)
* [License](#license)


#### Basic features

    TCP (stratum-like) protocol for server-push based jobs
        Compared to old HTTP protocol, this has a higher hash rate, lower network/CPU server load, lower orphan block percent, and less error prone
    IP banning to prevent low-diff share attacks
    Socket flooding detection
    Payment processing
        Splintered transactions to deal with max transaction size
        Minimum payment threshold before balance will be paid out
        Minimum denomination for truncating payment amount precision to reduce size/complexity of block transactions
    Detailed logging
    Ability to configure multiple ports - each with their own difficulty
    Variable difficulty / share limiter
    Share trust algorithm to reduce share validation hashing CPU load
    Clustering for vertical scaling
    Modular components for horizontal scaling (pool server, database, stats/API, payment processing, front-end)
    Live stats API (using AJAX long polling with CORS)
        Currency network/block difficulty
        Current block height
        Network hashrate
        Pool hashrate
        Each miners' individual stats (hashrate, shares submitted, pending balance, total paid, etc)
        Blocks found (pending, confirmed, and orphaned)
    An easily extendable, responsive, light-weight front-end using API to display data

#### Extra features

    Admin panel
        Aggregated pool statistics
        Coin daemon & wallet RPC services stability monitoring
        Log files data access
        Users list with detailed statistics
    Historic charts of pool's hashrate and miners count, coin difficulty, rates and coin profitability
    Historic charts of users's hashrate and payments
    Miner login(wallet address) validation
    Five configurable CSS themes
    Universal blocks and transactions explorer based on chainradar.com
    FantomCoin & MonetaVerde support
    Set fixed difficulty on miner client by passing "address" param with ".[difficulty]" postfix
    Prevent "transaction is too big" error with "payments.maxTransactionAmount" option

#### Support

    Since I am extreemly lazy I am not going to offer support.
    
    However both cryptonote-universal-pool & node-cryptonote-pool provide much of the needed support.
    
    https://github.com/fancoder/cryptonote-universal-pool
    https://github.com/zone117x/node-cryptonote-pool

#### Pools Using This Software

    http://monero.hiive.biz

#### Usage
Requirements

* Coin daemon(s) (find the coin's repo and build latest version from source)
* Node.js v0.10+ (follow these installation instructions)
* Redis key-value store v2.6+ (follow these instructions)
* libssl required for the node-multi-hashing module
  For Ubuntu: sudo apt-get install libssl-dev
* Boost is required for the cryptonote-util module
  For Ubuntu: sudo apt-get install libboost-all-dev

Seriously

Those are legitimate requirements. If you use old versions of Node.js or Redis that may come with your system package manager then you will have problems. Follow the linked instructions to get the last stable versions.

Redis security warning: be sure firewall access to redis - an easy way is to include bind 127.0.0.1 in your redis.conf file. Also it's a good idea to learn about and understand software that you are using - a good place to start with redis is data persistence.
1) Downloading & Installing

Clone the repository and run npm update for all the dependencies to be installed:

git clone https://github.com/zone117x/node-cryptonote-pool.git pool
cd pool
npm update

2) Configuration

Warning... I have only used this with Monero (XMR) and have no idea if it will work for other Cyrptonote coins.

Copy the config_example.json file to config.json then overview each options and change any to match your preferred setup.

Explanation for each field:

/* Used for storage in redis so multiple coins can share the same redis instance. */
"coin": "monero",

/* Used for front-end display */
"symbol": "MRO",

"logging": {

    "files": {

        /* Specifies the level of log output verbosity. This level and anything
           more severe will be logged. Options are: info, warn, or error. */
        "level": "info",

        /* Directory where to write log files. */
        "directory": "logs",

        /* How often (in seconds) to append/flush data to the log files. */
        "flushInterval": 5
    },

    "console": {
        "level": "info",
        /* Gives console output useful colors. If you direct that output to a log file
           then disable this feature to avoid nasty characters in the file. */
        "colors": true
    }
},

/* Modular Pool Server */
"poolServer": {
    "enabled": true,

    /* Set to "auto" by default which will spawn one process/fork/worker for each CPU
       core in your system. Each of these workers will run a separate instance of your
       pool(s), and the kernel will load balance miners using these forks. Optionally,
       the 'forks' field can be a number for how many forks will be spawned. */
    "clusterForks": "auto",

    /* Address where block rewards go, and miner payments come from. */
    "poolAddress": "4AsBy39rpUMTmgTUARGq2bFQWhDhdQNekK5v4uaLU699NPAnx9CubEJ82AkvD5ScoAZNYRwBxybayainhyThHAZWCdKmPYn"

    /* Poll RPC daemons for new blocks every this many milliseconds. */
    "blockRefreshInterval": 1000,

    /* How many seconds until we consider a miner disconnected. */
    "minerTimeout": 900,

    "ports": [
        {
            "port": 3333, //Port for mining apps to connect to
            "difficulty": 100, //Initial difficulty miners are set to
            "desc": "Low end hardware" //Description of port
        },
        {
            "port": 5555,
            "difficulty": 2000,
            "desc": "Mid range hardware"
        },
        {
            "port": 7777,
            "difficulty": 10000,
            "desc": "High end hardware"
        }
    ],

    /* Variable difficulty is a feature that will automatically adjust difficulty for
       individual miners based on their hashrate in order to lower networking and CPU
       overhead. */
    "varDiff": {
        "minDiff": 2, //Minimum difficulty
        "maxDiff": 100000,
        "targetTime": 100, //Try to get 1 share per this many seconds
        "retargetTime": 30, //Check to see if we should retarget every this many seconds
        "variancePercent": 30, //Allow time to very this % from target without retargeting
        "maxJump": 100 //Limit diff percent increase/decrease in a single retargetting
    },

    /* Feature to trust share difficulties from miners which can
       significantly reduce CPU load. */
    "shareTrust": {
        "enabled": true,
        "min": 10, //Minimum percent probability for share hashing
        "stepDown": 3, //Increase trust probability % this much with each valid share
        "threshold": 10, //Amount of valid shares required before trusting begins
        "penalty": 30 //Upon breaking trust require this many valid share before trusting
    },

    /* If under low-diff share attack we can ban their IP to reduce system/network load. */
    "banning": {
        "enabled": true,
        "time": 600, //How many seconds to ban worker for
        "invalidPercent": 25, //What percent of invalid shares triggers ban
        "checkThreshold": 30 //Perform check when this many shares have been submitted
    },
    /* [Warning: several reports of this feature being broken. Contributions to fix this are welcome.] 
        Slush Mining is a reward calculation technique which disincentivizes pool hopping and rewards 
        users to mine with the pool steadily: Values of each share decrease in time – younger shares 
        are valued higher than older shares. 
        More about it here: https://mining.bitcoin.cz/help/#!/manual/rewards */
    "slushMining": {
        "enabled": false, //Enables slush mining. Recommended for pools catering to professional miners
        "weight": 120, //defines how fast value assigned to a share declines in time
        "lastBlockCheckRate": 1 //How often the pool checks for the timestamp of the last block. Lower numbers increase load for the Redis db, but make the share value more precise.
    }
},

/* Module that sends payments to miners according to their submitted shares. */
"payments": {
    "enabled": true,
    "interval": 600, //how often to run in seconds
    "maxAddresses": 50, //split up payments if sending to more than this many addresses
    "mixin": 3, //number of transactions yours is indistinguishable from
    "transferFee": 5000000000, //fee to pay for each transaction
    "minPayment": 100000000000, //miner balance required before sending payment
    "denomination": 100000000000 //truncate to this precision and store remainder
},

/* Module that monitors the submitted block maturities and manages rounds. Confirmed
   blocks mark the end of a round where workers' balances are increased in proportion
   to their shares. */
"blockUnlocker": {
    "enabled": true,
    "interval": 30, //how often to check block statuses in seconds

    /* Block depth required for a block to unlocked/mature. Found in daemon source as
       the variable CRYPTONOTE_MINED_MONEY_UNLOCK_WINDOW */
    "depth": 60,
    "poolFee": 1.8, //1.8% pool fee (2% total fee total including donations)
    "devDonation": 0.1, //0.1% donation to send to pool dev - only works with Monero
    "coreDevDonation": 0.1 //0.1% donation to send to core devs - only works with Monero
},

/* AJAX API used for front-end website. */
"api": {
    "enabled": true,
    "hashrateWindow": 600, //how many second worth of shares used to estimate hash rate
    "updateInterval": 3, //gather stats and broadcast every this many seconds
    "port": 8117,
    "blocks": 30, //amount of blocks to send at a time
    "payments": 30, //amount of payments to send at a time
    "password": "test" //password required for admin stats
},

/* Coin daemon connection details. */
"daemon": {
    "host": "127.0.0.1",
    "port": 18081
},

/* Wallet daemon connection details. */
"wallet": {
    "host": "127.0.0.1",
    "port": 8082
},

/* Redis connection into. */
"redis": {
    "host": "127.0.0.1",
    "port": 6379,
    "auth": null //If set, client will run redis auth command on connect. Use for remote db
}

3) [Optional] Configure cryptonote-easy-miner for your pool

Your miners that are Windows users can use cryptonote-easy-miner which will automatically generate their wallet address and stratup multiple threads of simpleminer. You can download it and edit the config.ini file to point to your own pool. Inside the easyminer folder, edit config.init to point to your pool details

pool_host=example.com
pool_port=5555

Rezip and upload to your server or a file host. Then change the easyminerDownload link in your config.json file to point to your zip file.
4) Start the pool

node init.js

The file config.json is used by default but a file can be specified using the -config=file command argument, for example:

node init.js -config=config_backup.json

This software contains four distinct modules:

    pool - Which opens ports for miners to connect and processes shares
    api - Used by the website to display network, pool and miners' data
    unlocker - Processes block candidates and increases miners' balances when blocks are unlocked
    payments - Sends out payments to miners according to their balances stored in redis

By default, running the init.js script will start up all four modules. You can optionally have the script start only start a specific module by using the -module=name command argument, for example:

node init.js -module=api

Example screenshot of running the pool in single module mode with tmux.
5) Host the front-end

Simply host the contents of the website_example directory on file server capable of serving simple static files.

Edit the variables in the website_example/config.js file to use your pool's specific configuration. Variable explanations:

/* Must point to the API setup in your config.json file. */
var api = "http://poolhost:8117";

/* Minimum units in a single coin, for Bytecoin its 100000000. */
var coinUnits = 1000000000000;

/* Pool server host to instruct your miners to point to.  */
var poolHost = "cryppit.com";

/* IRC Server and room used for embedded KiwiIRC chat. */
var irc = "irc.freenode.net/#monero";

/* Contact email address. */
var email = "support@cryppit.com";

/* Market stat display params from https://www.cryptonator.com/widget */
var cryptonatorWidget = ["XMR-BTC", "XMR-USD", "XMR-EUR", "XMR-GBP"];

/* Download link to cryptonote-easy-miner for Windows users. */
var easyminerDownload = "https://github.com/zone117x/cryptonote-easy-miner/releases/";

/* Used for front-end block links. For other coins it can be changed, for example with
   Bytecoin you can use "https://minergate.com/blockchain/bcn/block/". */
var blockchainExplorer = "http://monerochain.info/block/";

/* Used by front-end transaction links. Change for other coins. */
var transactionExplorer = "http://monerochain.info/tx/";

6) Customize your website

The following files are included so that you can customize your pool website without having to make significant changes to index.html or other front-end files thus reducing the difficulty of merging updates with your own changes:

    custom.css for creating your own pool style
    custom.js for changing the functionality of your pool website

Then simply serve the files via nginx, Apache, Google Drive, or anything that can host static content.
Upgrading

When updating to the latest code its important to not only git pull the latest from this repo, but to also update the Node.js modules, and any config files that may have been changed.

    Inside your pool directory (where the init.js script is) do git pull to get the latest code.
    Remove the dependencies by deleting the node_modules directory with rm -r node_modules.
    Run npm update to force updating/reinstalling of the dependencies.
    Compare your config.json to the latest example ones in this repo or the ones in the setup instructions where each config field is explained. You may need to modify or add any new changes.


Credit to surfer43 for these instructions
JSON-RPC Commands from CLI

Documentation for JSON-RPC commands can be found here:

    Daemon https://wiki.bytecoin.org/wiki/Daemon_JSON_RPC_API
    Wallet https://wiki.bytecoin.org/wiki/Wallet_JSON_RPC_API

Curl can be used to use the JSON-RPC commands from command-line. Here is an example of calling getblockheaderbyheight for block 100:

curl 127.0.0.1:18081/json_rpc -d '{"method":"getblockheaderbyheight","params":{"height":100}}'

#### Monitoring Your Pool

    To inspect and make changes to redis I suggest using redis-commander
    To monitor server load for CPU, Network, IO, etc - I suggest using New Relic
    To keep your pool node script running in background, logging to file, and automatically restarting if it crashes - I suggest using forever

#### Donations

    BTC: 1K4N5msYZHse6Hbxz4oWUjwqPf8wu6ducV
    XMR: 42VxjBpfi4TS6KFjNrrKo3QLcyK7gBGfM9w7DxmGRcocYnEbJ1hhZWXfaHJtCXBxnL74DpkioPSivjRYU8qkt59s3EaHUU3

#### Credits

    Many Bothans died getting this pool to you. Honor them by sending me some BTC or XMR.
    
    https://github.com/fancoder/cryptonote-universal-pool
    https://github.com/zone117x/node-cryptonote-pool

#### License

Released under the GNU General Public License v2

http://www.gnu.org/licenses/gpl-2.0.html
