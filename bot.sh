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
if [[ "$LINE" =~ ^.{17}\<(.*)\>\ (.*)$ ]]; then SENDER="${BASH_REMATCH[1]}"; MESSAGE="${BASH_REMATCH[2]}"; fi

# public commands
if [[ "$MESSAGE" == "!source" ]]; then sendToIRC "https://github.com/0sudoman/GrigoriBot"; fi
if [[ "$MESSAGE" == "${BOTNICK}++" ]]; then sendToIRC ":D"; fi
if [[ "$MESSAGE" == "${BOTNICK}--" ]]; then sendToIRC "D:"; fi

# admin commands
if [[ $SENDER == $ADMIN ]]; then
if [[ "$MESSAGE" == "!sort (.*)$" ]]; then ./sort.sh "${BASH_REMATCH[1]}"; fi
#if [[ "$MESSAGE" == "!reboot" ]]; then sendToIRC "Rebooting all systems."; ./reboot.sh; fi
if [[ "$MESSAGE" == "!shutdown" ]]; then sendToIRC "Shutting down all systems."; ./shutdown.sh; fi
fi

fi
done
