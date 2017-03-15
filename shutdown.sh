#!/bin/bash
# shutdown.sh
# kills all bot functions

source config.sh
SCRIPT="shutdown.sh"
sendToLog "Started"

screen -S ii -X kill
screen -S rejoiner -X kill
screen -S bot -X kill
screen -S dbot -X kill

sendToLog "Finished"
exit
