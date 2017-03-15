#!/bin/bash
# rejoiner.sh
# keeps the bot joined

source config.sh
SCRIPT="rejoiner.sh"
sendToLog "Started"

while true; do

echo "/j $CHANNEL" > $IIDIR/$SERVER/in
sleep $JOINDELAY

done
