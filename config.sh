#!/bin/bash
# config.sh
# stores all settings

LOGFILE="logs/latest.log"
if [[ ! -f $LOGFILE ]]; then
  mkdir "logs"
  LOGFILE="logs/latest.log"
  echo "$( date ): Log file not found. Resetting to default." >> $LOGFILE
fi

# IRC SETTINGS
IIDIR="/home/justin/irc"  #the directory where ii is located
SERVER="irc.dtella.net"   #the server to connect to
CHANNEL="#ravenholm"      #the channel to be active in
BOTNICK="GrigoriBot"      #the nick of the bot
ADMIN="FatherGrigori"     #the nick of the owner
JOINDELAY="10"            #the delay between sending /j messages (higher numbers reduce flooding)

IRC="$IIDIR/$SERVER/#$CHANNEL"
