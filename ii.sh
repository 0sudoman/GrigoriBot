#!/bin/bash
# ii.sh
# starts the ii interface

source config.sh
echo "$( date ): ii.sh run" >> $LOGFILE

screen -dm -S ii ii -s $SERVER -n $BOTNICK

exit
