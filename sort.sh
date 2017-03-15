#!/bin/bash
# sort.sh
# sorts out TV shows and shit

source config.sh
SCRIPT="sort.sh"
sendToLog "Started"

DIR="$1"

SHOW="UNKNOWN"
SEASON="UNKNOWN"
EPISODE="UNKNOWN"
QUALITY="UNKNOWN"
TYPE="UNKNOWN"
EXIT="false"

# determine show name
#  improved algorithm
for SHOW in $TVOUT/*; do
  if [[ "$SHOW" =~ .{${#TVOUT}}.(.*)$ ]]; then SHOWNAME="${BASH_REMATCH[1]}"; fi
  if [[ "$SHOW" =~ .{${#TVOUT}}.(.{1,13}) ]]; then SHOWMOD="${BASH_REMATCH[1]}"; fi
  SHOWMOD=${SHOWMOD/\ /\.} && SHOWMOD=${SHOWMOD/\ /\.} && SHOWMOD=${SHOWMOD/\ /\.}
  SHOWMOD=${SHOWMOD/\'/} && SHOWMOD=${SHOWMOD/\(/} && SHOWMOD=${SHOWMOD/\)/}
  if [[ $1 =~ ^"$SHOWMOD" ]]; then SHOW="$SHOWNAME"; break; fi
done

# determine season / episode
for i in $( seq -w 30 ); do if [[ "$DIR" =~ .*[Ss]$i.* ]]; then SEASON="$i"; fi; done
for i in $( seq -w 30 ); do if [[ "$DIR" =~ .*[Ee]$i.* ]]; then EPISODE="$i"; fi; done

# determine quality
if [[ $DIR =~ "HDTV" ]]; then QUALITY="SD"; fi
if [[ $DIR =~ "720p" ]]; then QUALITY="720p"; fi
if [[ $DIR =~ "1080p" ]]; then QUALITY="1080p"; fi;

# determine filetype
if [[ -n $( find "$IN/$DIR" -name *.mkv ) ]]; then TYPE="mkv"; fi;
if [[ -n $( find "$IN/$DIR" -name *.rar ) ]]; then TYPE="rar"; fi;

# concatenate target directory
TARGET="$TVOUT/$SHOW/Season $SEASON/"

# see if assumptions make sense
OUTPUT="Transferring $SHOW S$SEASON E$EPISODE $QUALITY"
if [ "$SHOW" == "UNKNOWN" ] || [ $SEASON == "UNKNOWN" ] || [ $EPISODE == "UNKNOWN" ] || [ $TYPE == "UNKNOWN" ]; then
  sendToIRC "Cannot find necessary data." && exit
fi
if [[ -n $( find "$TARGET" -name *[Ee]$EPISODE* ) ]]; then
  sendToIRC "Target file already exists." && exit
fi

# extract/copy as needed
sendToIRC "Transferring $SHOW S$SEASON E$EPISODE $QUALITY"
if [ $TYPE == mkv ]; then cp "$IN/$DIR/*.mkv" "$TARGET"; fi
if [ $TYPE == rar ]; then unrar e "$IN/$DIR/*.rar" "$TARGET"; fi

# verify file was copied
if [[ -n $( find "$TARGET" -name *[Ee]$EPISODE* ) ]]; then
  sendToIRC "Transfer successful."
  sendtoDiscord "New in TV: $SHOW S${SEASON}E${EPISODE}"
else
  sendToIRC "Transfer failed." && exit
fi

sendToLog "Finished"
exit
