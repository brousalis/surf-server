## csgo surf server setup

this project is intended for personal use, so my personal server settings are included. also, I have never setup a srcds server before, so it's likely i've done things incorrectly. 

> if you run into problems, I took some notes on setting up a local surf server manually on Ubuntu 14.10 [here](https://github.com/brousalis/surf-timer/blob/master/SERVER.md).

includes:

  - ZipCore's [Timer](http://github.com/zipcore/timer)
  - [metamod 1.104](https://www.sourcemm.net/) and vdf
  - [sourcemod 1.6.4-git4624](http://www.sourcemod.net/snapshots.php) (1.7+ is not compatible with timer)
  - [surf_kitsune](http://css.gamebanana.com/maps/179653) by Arblarg (stage test map)
  - [surf_3](http://csgo.gamebanana.com/maps/181256) by Umg_ (linear test map)
  - [sm_knifeupgrade](https://forums.alliedmods.net/showthread.php?p=2160622) by klexen (!knife)
  - [disableradar](https://forums.alliedmods.net/showthread.php?p=2138783) by Internet Bully (hides radar)

requirements:

  - linux-based server (tested on Ubuntu 14.10). works in a virtual machine as well.
  - `lib32gcc1 libc6-i386 lamp-server` dependencies for the server
  - mysql (configured with lamp-server)
    
---
### getting started

- [download](http://www.ubuntu.com/download/desktop) Ubuntu 14.10 or 14.04.01
- install on a desktop or virtual machine
- open up Terminal and run `sudo apt-get install lib32gcc1 libc6-i386 lamp-server git`
- when asked for root password for mysql, leave it blank
  - if you want to set it because you're setting up a public server, make sure to update `addons/sourcemod/configs/databases.cfg`
- clone this repo `git clone https://github.com/brousalis/surf-server/ ~/surf-server`
- `cd ~/surf-server` 
- `script/install`

read below to see what the install script does. if all goes well, you should be able to go into the server directory and start the server:

    cd ~/csgo_ds
    ./start
    
and your server should be running. try connecting to it through LAN

> **IMPORTANT** you will want to configure the server settings, since this is my personal setup (add yourself as admin, rename the server, etc...)

---
### scripts
these are horribly written, but have been working for me. deal with it

#### `script/install`
- downloads [steamCMD](https://developer.valvesoftware.com/wiki/SteamCMD#Downloading_SteamCMD)
- installs CSGO Dedicated Server (740) into `~/csgo_ds`
- runs `script/setup`, copies the surf timer assets to the dedicated server folder
- runs `script/compile`, recompiles the plugins and copies them to the server
- runs `script/sql`, sets up the database for the server

#### `script/compile`
compiles all of the timer's `.sp` files to `.smx` files and places them in your server's `sourcemod/plugins` folder, and the local plugins folder. the core timer plugins are located in `sourcemod/scripting/timer` if you want to modify them

#### `script/setup`
copies sourcemod, metamod, and the rest of the surf timer assets to your server in `~/csgo`

#### `script/sql`
this script sets up the mysql database, named `surf_server`. then it runs the import scripts for the mapzones, maptiers, and sourcemod tables on the database.

#### `script/update`
use this when the dedicated server files get updated and your server is out of date. or, when your server will not start up.

---
### making it public
in order for people to connect to your server, setup port forwarding on your router for:

    27015 TCP/UDP
    27020 UDP
    27005 UDP
    51840 UDP
    
