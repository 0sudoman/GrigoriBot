#!/bin/bash
# ibot.sh
# sends commands to bot.sh
# I still don't like the name

botDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$botDir/config.sh"
scriptName="ibot.sh"
logInfo "Started"

rejoinTime=$( date +%s )

while true; do

# grab a new line
newLine="$( tail -n1 $ircDir/out )"
if [[ "$newLine" != "$line" ]]; then
  line="$newLine"
  "$botDir/bot.sh" "$line"
fi

# join the channel
if [[ $( date +%s ) == $rejoinTime ]] || [[ $line =~ "kicked $botNick" ]]; then
  rejoinTime=$( expr $( date +%s ) + $ircJoinDelay )
  echo "/j $ircChannel" > $iiDir/$ircServer/in
  echo "nothing" >> $iiDir/out  #super hacky way to prevent flooding
fi

done
