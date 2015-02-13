# surf-server
some notes I took while setting up a local surf server on Ubuntu
14.10 64bit

### steamcmd
steamcmd downloads the dedicated servers from valve

    wget http://media.steampowered.com/installer/steamcmd_linux.tar.gz
    tar -xvzf steamcmd_linux.tar.gz
    cd steamcmd
    
### get dedicated server

    ./steamcmd.sh +login anonymous +force_install_dir ~/csgo_ds +app_update 740 +quit
    
> **NOTE** `app_update` might fail, rerun it without `validate`. this command also upgrades the server after a game update

the files for the CSGO dedicated server get downloaded into your `~/csgo_ds` folder.

### install metamod

    curl http://sourcemod.gameconnect.net/files/mmsource-1.10.4-linux.tar.gz | tar xvz
    
this'll create an addons folder in your root. don't worry, we aren't going to leave it there.

### install sourcemod

we need to use a specific version of sourcemod for the Timer's compatibility sake

    curl http://www.sourcemod.net/smdrop/1.6/sourcemod-1.6.4-git4624-linux.tar.gz | tar xvz

this will add a `sourcemod` folder to the previously created addons folder, and create a `cfg` folder.
now we need to move these two folders into the `csgo` folder.

    mv addons csgo/addons
    mv cfg/* csgo/cfg
    rm -rf cfg

### setup mysql

laziest way to do it

    sudo apt-get install lamp-server
    
extreme laziness is to use no password for root. 

this also installs `phpmyadmin`. if you're like me, you'll need to do this too:
    
> **NOTE** using phpmyadmin and configurating is optional

    vim /etc/phpmyadmin/config.inc.php
    uncomment line 101 ['AllowNoPassword'] = TRUE

create the database

    mysql -u root -e "create database surf_server"; 
    
the database stores scores, map zones, and map tiers. you'll fill it below.

### setup the database

    cd ~/csgo_ds
    vim addons/sourcemod/configs/databases.cfg
    copy `"default"` and name it `"timer"`
    change `"database"` to `"surf_server"`
    
sometimes, shit gets real:

    sudo ln -s /var/run/mysqld/mysqld.sock /tmp/mysql.sock
    
will fix issues with running the server later.

### setup the timer

clones down the timer repo, runs the bootstrap scripts

    git clone https://github.com/brousalis/surf-timer ~/surf-timer
    cd ~/surf-timer
    ./compile
    ./setup
    ./sql
    
### add a map for testing

    cd ~/csgo_ds/csgo/maps
    wget http://files.gamebanana.com/maps/surf_kitsune.rar 
    unrar x surf_kitsune.rar
    
### create a script to run the server

    cd ~/csgo_ds
    echo "./srcds_run -game csgo -console -usercon +mapgroup mg_surf +map surf_kitsune" >> start
    chmod +x start

---

you should be able to connect to a LAN server (10.0.0.15:27016 probably) running surf_kitsune, and the timer showing now, we have to configure the server settings (gravity, airaccel), game type settings (no bots, round times), admin, and map groups. onwards!

---

### add yourself as admin

go to [steamidfinder.com](http://steamidfinder.com), find your id.

    vim addons/sourcemod/configs/admins_simple.ini
    "STEAM_0:0:5606506" "z"
    
the `z` flag gives you all admin rights.

### mapgroups and mapcycle

### rockthevote 

to enable rtv, move the files from `addons/sourcemod/plugins/disabled` to `addon/sourcemod/plugins/`

    disabled/rockthevote.smx
    disabled/mapchooser.smx
    disabled/nominations.smx

### knife mod

download [sm_knifeupgrade](https://forums.alliedmods.net/showthread.php?p=2160622)

put `sm_knifeupgrade.smx` in the `addon/sourcemod/plugins` folder.
put `knifeupgrade.phrases.txt` in the `addon/sourcemod/translations` folder.

