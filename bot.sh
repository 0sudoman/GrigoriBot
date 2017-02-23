#!/bin/bash
# bot.sh
# responds to commands

source config.sh
echo "$( date ): bot.sh started" >> $LOGFILE

while true; do
# grab a new line
NEW="$( tail -n1 $IRC/out )"
if [ "$LINE" != "$NEW" ]; then
LINE="$NEW"

# public commands
if [[ "$LINE" =~ "> !source" ]]; then echo "lolno" > $IRC/in; fi

# admin commands
if [[ "$LINE" =~ ^.{17}"<$ADMIN> !sort" ]]; then echo "lolno" > $IRC/in ; fi
if [[ "$LINE" =~ ^.{17}"<$ADMIN> !reconnect" ]]; then echo "Restarting IRC interface." > $IRC/in; ./reconnect.sh; fi
if [[ "$LINE" =~ ^.{17}"<$ADMIN> !shutdown" ]]; then echo "Shutting down all systems." > $IRC/in; ./shutdown.sh; fi

fi
done
