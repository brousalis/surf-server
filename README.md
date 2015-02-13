# surf-timer

using Zipcore's surf timer. 

this is intended for personal use. my server settings are included.

if you run into problems, I took some notes on setting up a local surf server manually on Ubuntu 14.10 [here](https://github.com/brousalis/surf-timer/blob/master/SERVER.md)

includes:

  - metamod 1.10.4
  - metamod csgo .vdf
  - sourcemod 1.6.4-git4624 (1.7+ is not compatible with timer)
  - zipcore's timer
  - surf_kitsune by Arblarg ([http://css.gamebanana.com/maps/179653](http://css.gamebanana.com/maps/179653))
  - sm_knifeupgrade by klexen ([https://forums.alliedmods.net/showthread.php?p=2160622](https://forums.alliedmods.net/showthread.php?p=2160622))
  - disableradar by Internet Bully ([https://forums.alliedmods.net/showthread.php?p=2138783](https://forums.alliedmods.net/showthread.php?p=2138783))

> **NOTE** scripts work assuming your CSGO Dedicated Server lives in `~/csgo_ds`, which by default is what `./install` does

#### `./install`

    - downloads `steamCMD`
    - installs CSGO Dedicated Server in `~/csgo_ds`
    - runs `./setup`, copies the surf timer assets to the dedicated server
    - runs `./compile`, recompiles the plugins and copies them to the server
    - runs `./sql`, sets up the database for the server

#### `./compile`

compiles all of the timer's `.sp` files to `.smx` files and places them in your server's `sourcemod/plugins` folder, and the local plugins folder. 

again, assuming the server lives in `~/csgo_ds`

#### `./setup`

copies the rest of the surf timer assets to your server.

# making it public

in order for people to connect to your server, setup port forwarding for:

    27015 TCP/UDP
    27020 UDP
    27005 UDP
    51840 UDP
