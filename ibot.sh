#!/bin/bash
# ibot.sh
# sends commands to bot.sh
# I still don't like the name

botDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$botDir/config.sh"
scriptName="ibot.sh"
logInfo "Started"

rejoinTime=$( date +%s )
echo "/j $ircChannel" > $iiDir/$ircServer/in

while inotifywait -q -e modify "$ircDir/out" >/dev/null; do

  newLine="$( tail -n1 $ircDir/out )"
  if [[ "$newLine" != "$line" ]]; then
    line="$newLine"
    "$botDir/bot.sh" "$line"
  fi

  if [[ $( date +%s ) -ge $rejoinTime ]] || [[ $line =~ "kicked $botNick" ]]; then
    echo "/j $ircChannel" > $iiDir/$ircServer/in
    rejoinTime=$( expr $( date +%s ) + $ircJoinDelay )
  fi
done
