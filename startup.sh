#!/bin/bash
# startup.sh
# starts all bot functions

source config.sh
echo "$( date ): startup.sh run" >> $LOGFILE

./ii.sh
screen -dm -S rejoin ./rejoin.sh
screen -dm -S bot ./bot.sh
