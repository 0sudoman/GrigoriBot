#!/bin/bash
# bot.sh
# responds to commands
# this is seperate now so it can be edited on-the-fly without rebooting

botDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$botDir/config.sh"
scriptName="bot.sh"

ircLine="$1"
if [[ "$ircLine" =~ ^.{17}\<(.*)\>\ (.*)$ ]]; then
  ircSender="${BASH_REMATCH[1]}"
  ircMessage="${BASH_REMATCH[2]}"
fi
if [[ "$ircMessage" =~ ^(.*)\ (.*)$ ]]; then
  ircCommand="${BASH_REMATCH[1],,}"
  ircExtra="${BASH_REMATCH[2]}"
else
  ircCommand="${ircMessage,,}"
fi

if [[ "$ircSender" != "$botNick" ]]; then

# public commands
if [[ "$ircCommand" == "!help" ]]; then sendToIRC "You can find my docs at https://github.com/0sudoman/GrigoriBot/blob/master/docs.md"; fi
if [[ "$ircCommand" == "!source" ]]; then sendToIRC "https://github.com/0sudoman/GrigoriBot"; fi
if [[ "$ircCommand" == "!fortune" ]]; then sendToIRC "$(fortune)"; fi
if [[ "$ircCommand" == "!freespace" ]]; then sendToIRC "$(df -h | grep md0p1)"; fi
if [[ "$ircCommand" == "${BOTNICK,,}++" ]]; then sendToIRC ":D"; fi
if [[ "$ircCommand" == "${BOTNICK,,}--" ]]; then sendToIRC "D:"; fi

# admin commands
if [[ "$ircSender" == "$ircAdmin" ]]; then

#if [[ "$ircCommand" == "!reboot" ]]; then sendToIRC "Rebooting all systems."; botReboot; fi
#if [[ "$ircCommand" == "!shutdown" ]]; then sendToIRC "Shutting down all systems."; botShutdown; fi
if [[ "$ircCommand" =~ "!sort" ]]; then "$botDir/sort.sh" "$ircExtra"; fi

fi
fi
exit
