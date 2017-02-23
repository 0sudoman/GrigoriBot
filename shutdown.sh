#!/bin/bash
# shutdown.sh
# kills all bot functions

source config.sh
echo "$( date ): shutdown.sh run" >> $LOGFILE

screen -S ii -X kill
screen -S rejoin -X kill
screen -S bot -X kill
