#!/bin/bash
# reboot.sh
# reboots all bot functions

source config.sh
SCRIPT="reboot.sh"
sendToLog "Started"

./shutdown.sh

sleep 5

./startup.sh

sendToLog "Finished"
exit
