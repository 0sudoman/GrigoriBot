#!/bin/bash
# ibot.sh
# sends commands to bot.sh
# I still don't like the name

BOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$BOTDIR/config.sh"
SCRIPT="ibot.sh"
sendToLog "Started"

REJOIN=$( date +%s )

while true; do

# grab a new line
NEW="$( tail -n1 $IRC/out )"
if [[ "$LINE" != "$NEW" ]]; then LINE="$NEW"; "$BOTDIR/bot.sh" "$LINE"; fi

# join the channel
if [[ $( date +%s ) == $REJOIN ]] || [[ $LINE =~ "kicked $BOTNICK" ]]; then
  REJOIN=$( expr $( date +%s ) + $JOINDELAY )
  echo "/j $CHANNEL" > $IIDIR/$SERVER/in
  echo "nothing" >> $IRC/out  #super hacky way to prevent flooding
fi

done
