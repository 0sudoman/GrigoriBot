#!/bin/bash
# bot.sh
# responds to commands
# this is seperate now so it can be edited on-the-fly without rebooting

source config.sh
SCRIPT="bot.sh"

LINE="$1"
if [[ "$LINE" =~ ^.{17}\<(.*)\>\ (.*)$ ]]; then SENDER="${BASH_REMATCH[1]}"; MESSAGE="${BASH_REMATCH[2]}"; fi
if [[ "$MESSAGE" =~ ^(.*)\ (.*)$ ]]; then MESSAGE="${BASH_REMATCH[1]},,"; EXTRA="${BASH_REMATCH[2]}"
else MESSAGE="${MESSAGE,,}"; fi
if [[ $SENDER != $BOTNICK ]]; then

# public commands
if [[ "$MESSAGE" == "!help" ]]; then sendToIRC "You can find my docs at https://github.com/0sudoman/GrigoriBot/blob/master/docs.md"; fi
if [[ "$MESSAGE" == "!source" ]]; then sendToIRC "https://github.com/0sudoman/GrigoriBot"; fi
if [[ "$MESSAGE" == "${BOTNICK}++" ]]; then sendToIRC ":D"; fi
if [[ "$MESSAGE" == "${BOTNICK}--" ]]; then sendToIRC "D:"; fi

# admin commands
if [[ $SENDER == $ADMIN ]]; then
if [[ "$MESSAGE" =~ "!sort" ]]; then ./sort.sh "$EXTRA"; fi
#if [[ "$MESSAGE" == "!reboot" ]]; then sendToIRC "Rebooting all systems."; botReboot; fi
#if [[ "$MESSAGE" == "!shutdown" ]]; then sendToIRC "Shutting down all systems."; botShutdown; fi
fi

fi
