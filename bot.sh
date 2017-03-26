#!/bin/bash
# bot.sh
# responds to commands

source config.sh
SCRIPT="bot.sh"
sendToLog "Started"

while true; do
# grab a new line
NEW="$( tail -n1 $IRC/out )"
if [ "$LINE" != "$NEW" ]; then LINE="$NEW"

# public commands
if [[ "$LINE" =~ "> !source" ]]; then sendToIRC "https://github.com/0sudoman/GrigoriBot"; fi
if [[ "$LINE" =~ "> ${BOTNICK}++" ]]; then sendToIRC ":D"; fi
if [[ "$LINE" =~ "> ${BOTNICK}++" ]]; then sendToIRC "D:"; fi

# admin commands
if [[ "$LINE" =~ ^.{17}"<$ADMIN> !sort "(.*) ]]; then ./sort.sh "${BASH_REMATCH[1]}"; fi
#if [[ "$LINE" =~ ^.{17}"<$ADMIN> !reboot" ]]; then sendToIRC "Rebooting all systems."; ./reboot.sh; fi
if [[ "$LINE" =~ ^.{17}"<$ADMIN> !shutdown" ]]; then sendToIRC "Shutting down all systems."; ./shutdown.sh; fi

fi
done
