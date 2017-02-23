#!/bin/bash
# rejoin.sh
# keeps the bot joined

source config.sh
echo "$( date ): rejoin.sh started" >> $LOGFILE

while true; do

echo "/j $CHANNEL" > $IRC/in
sleep $JOINDELAY

done
