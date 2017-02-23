#!/bin/bash
# reboot.sh
# reboots all bot functions

source config.sh
echo "$( date ): reboot.sh run" >> $LOGFILE

./shutdown.sh

sleep 5

./startup.sh
