#!/bin/bash
# rejoiner.sh
# keeps the bot joined

source config.sh
echo "$( date ): rejoiner.sh started" >> $LOGFILE

while true; do

echo "/j $CHANNEL" > $IRC/in
sleep $JOINDELAY

done
