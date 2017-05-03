#!/bin/bash
# iinterface.sh
# sends commands to bot.sh
# I still don't like the name

source config.sh
SCRIPT="iinterface.sh"
sendToLog "Started"

REJOIN=$( date +%s )

while true; do

# grab a new line
NEW="$( tail -n1 $IRC/out )"
if [[ "$LINE" != "$NEW" ]]; then LINE="$NEW"; ./bot.sh "$LINE"; fi

# join the channel
if [[ $( date +%s ) == $REJOIN ]] || [[ $LINE =~ "kicked $BOTNICK" ]]; then
  REJOIN=$( expr $( date +%s ) + $JOINDELAY )
  echo "/j $CHANNEL" > $IIDIR/$SERVER/in
  echo "nothing" >> $IRC/out  #super hacky way to prevent flooding
fi

done
