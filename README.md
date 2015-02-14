### csgo surf server setup

using ZipCore's [Timer](http://github.com/zipcore/timer). project is intended for personal use, my personal settings are included. 

> if you run into problems, I took some notes on setting up a local surf server manually on Ubuntu 14.10 [here](https://github.com/brousalis/surf-timer/blob/master/SERVER.md)

includes:

  - ZipCore's [Timer](http://github.com/zipcore/timer)
  - [metamod 1.104](https://www.sourcemm.net/) and vdf
  - [sourcemod 1.6.4-git4624](http://www.sourcemod.net/snapshots.php) (1.7+ is not compatible with timer)
  - [surf_kitsune](http://css.gamebanana.com/maps/179653) by Arblarg (test map)
  - [sm_knifeupgrade](https://forums.alliedmods.net/showthread.php?p=2160622) by klexen (!knife)
  - [disableradar](https://forums.alliedmods.net/showthread.php?p=2138783) by Internet Bully

---

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

you can `sudo apt-get install lamp-server` to get everything you need for the database, as well as phpmyadmin.

this script sets up the mysql database, named `surf_server`. then it runs the import scripts for the mapzones, maptiers, and sourcemod tables on the database.


#### `script/update`

use this when the dedicated server files get updated and your server is out of date.

---

#### making it public

in order for people to connect to your server, setup port forwarding on your router for:

    27015 TCP/UDP
    27020 UDP
    27005 UDP
    51840 UDP
