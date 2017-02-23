#!/bin/bash
# reconnect.sh
# reconnects the ii interface

source config.sh
echo "$( date ): reconnect.sh run" >> $LOGFILE

screen -S ii -X kill

sleep 5

./ii.sh
