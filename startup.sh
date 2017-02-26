#!/bin/bash
# startup.sh
# starts all bot functions

source config.sh
echo "$( date ): startup.sh run" >> $LOGFILE

./ii.sh
screen -dm -S rejoiner ./rejoiner.sh
screen -dm -S bot ./bot.sh
screen -dm -S dbot python3 ./dbot.py $TOKEN
