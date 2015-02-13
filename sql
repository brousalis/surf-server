#!/bin/bash

for mapzone in addons/sourcemod/gamedata/mapzones/*.sql
do
  mysql -u root sourcemod < $mapzone
done
