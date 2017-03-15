#!/bin/bash
# startup.sh
# starts all bot functions

source config.sh
SCRIPT="startup.sh"
sendToLog "Started"

screen -dm -S ii ii -s $SERVER -n $BOTNICK
screen -dm -S rejoiner ./rejoiner.sh
screen -dm -S bot ./bot.sh
screen -dm -S dbot python3 ./dbot.py $TOKEN

sendToLog "Finished"
exit
