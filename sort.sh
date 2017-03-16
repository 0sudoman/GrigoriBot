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

# determine show name
#  improved algorithm
for SHOW in $TVOUT/*; do
  if [[ "$SHOW" =~ .{${#TVOUT}}.(.*)$ ]]; then SHOWNAME="${BASH_REMATCH[1]}"; fi
  if [[ "$SHOW" =~ .{${#TVOUT}}.(.{1,13}) ]]; then SHOWMOD="${BASH_REMATCH[1]}"; fi
  SHOWMOD=${SHOWMOD/\ /\.} && SHOWMOD=${SHOWMOD/\ /\.} && SHOWMOD=${SHOWMOD/\ /\.}
  SHOWMOD=${SHOWMOD/\'/} && SHOWMOD=${SHOWMOD/\(/} && SHOWMOD=${SHOWMOD/\)/}
  if [[ "$DIR" =~ ^"$SHOWMOD" ]]; then SHOW="$SHOWNAME"; SORT="TV"; break; fi
done

# determine quality & filetype
if [[ $DIR =~ "720p" ]]; then QUALITY="720p"; fi
if [[ $DIR =~ "1080p" ]]; then QUALITY="1080p"; fi
if [[ -n $( find "$IN/$DIR" -name *.mkv ) ]]; then TYPE="mkv"; fi
if [[ -n $( find "$IN/$DIR" -name *.rar ) ]]; then TYPE="rar"; fi

if [[ $SORT == "TV" ]]; then
  # determine season & episode
  for i in $( seq -w 30 ); do if [[ "$DIR" =~ .*[Ss]$i.* ]]; then SEASON="$i"; fi; done
  for i in $( seq -w 30 ); do if [[ "$DIR" =~ .*[Ee]$i.* ]]; then EPISODE="$i"; fi; done

  # check for errors
  TARGET="$TVOUT/$SHOW/Season $SEASON/"
  if [ $SEASON == "UNKNOWN" ] || [ $EPISODE == "UNKNOWN" ]; then sendToIRC "Could not find necessary data. Terminating."; exit; fi
  if [[ -n $( find "$TARGET" -name *[Ee]$EPISODE* ) ]]; then sendToIRC "Target file already exists. Terminating."; exit; fi

  # transfer
  sendToIRC "Transferring $SHOW S${SEASON}E${EPISODE} $QUALITY"
  if [[ $TYPE == mkv ]]; then cp "$IN/$DIR/*.mkv" "$TARGET"; fi
  if [[ $TYPE == rar ]]; then unrar e "$IN/$DIR/*.rar" "$TARGET"; fi

  # verify
  if [[ -n $( find "$TARGET" -name *[Ee]$EPISODE* ) ]]; then
    sendToIRC "TV Transfer Successful."
    sendtoDiscord "New in TV: $SHOW S${SEASON}E${EPISODE}"
  else
    sendToIRC "TV Transfer Failed." && exit
  fi
fi

sendToLog "Finished"
exit
