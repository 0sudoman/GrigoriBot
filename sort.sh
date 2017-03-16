#!/bin/bash
# sort.sh
# sorts out TV shows and shit

source config.sh
SCRIPT="sort.sh"
sendToLog "Started"

DIR="$1"
SEASON="UNKNOWN"
EPISODE="UNKNOWN"
QUALITY="UNKNOWN"
TYPE="UNKNOWN"

# determine show name
#  improved algorithm
for SHOW in $TVOUT/*; do
  if [[ "$SHOW" =~ .{${#TVOUT}}.(.*)$ ]]; then SHOWNAME="${BASH_REMATCH[1]}"; fi
  if [[ "$SHOW" =~ .{${#TVOUT}}.(.{1,13}) ]]; then SHOWMOD="${BASH_REMATCH[1]}"; fi
  for i in $( seq 5 ); do SHOWMOD=${SHOWMOD/\ /\.}; done
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
  if [ $SEASON == "UNKNOWN" ] || [ $EPISODE == "UNKNOWN" ] || [ $TYPE == "UNKNOWN" ]; then sendToIRC "Could not find necessary data. Terminating."; exit; fi
  if [[ -n $( find "$TARGET" -name *[Ee]$EPISODE* ) ]]; then sendToIRC "Target file already exists. Terminating."; exit; fi

  # transfer
  sendToIRC "Transferring $SHOW S${SEASON}E${EPISODE} $QUALITY"
  if [[ $TYPE == mkv ]]; then cp "$IN/$DIR/*.mkv" "$TARGET"; fi
  if [[ $TYPE == rar ]]; then unrar e "$IN/$DIR/*.rar" "$TARGET"; fi

  # verify
  if [[ -n $( find "$TARGET" -name *[Ee]$EPISODE* ) ]]; then
    sendToIRC "TV Transfer Successful."
    sendToDiscord "New in TV: $SHOW S${SEASON}E${EPISODE}"
  else
    sendToIRC "TV Transfer Failed." && exit
  fi
else
  # determine movie name and year
  if [[ $DIR =~ (.*).(19|20)([0-9]{2}) ]]; then MOVIENAME="${BASH_REMATCH[1]}"; YEAR="${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; else sendToIRC "Could not find necessary data. Terminating."; fi
  for i in $( seq 10 ); do MOVIENAME=${MOVIENAME/\./\ }; done

  # check for errors
  if [[ -n $( find "$MVOUT" -name "$MOVIENAME"* ) ]]; then sendToIRC "Target file already exists. Terminating."; exit; fi

  # transfer
  OUTNAME="$MOVIENAME [$YEAR] [$QUALITY]"
  sendToIRC "Transferring Movie: $OUTNAME"
  if [[ $TYPE == mkv ]]; then
    SOURCE="$( ls -S $IN/$DIR | grep $TYPE | head -1 )"
    cp "$IN/$DIR/$SOURCE" "$MVOUT/$OUTNAME.$TYPE"
  fi
  if [[ $TYPE == rar ]]; then
    for i in $( seq 8 ); do TEMPFILE="${TEMPFILE}$(( RANDOM % 10 ))"; done
    mkdir "$TEMP/$TEMPFILE"
    unrar e "$IN/$DIR/*.rar" "$TEMP/$TEMPFILE"
    SOURCE="$( ls -S $TEMP/$TEMPFILE | head -1 )"
    mv "$TEMP/$TEMPFILE/$SOURCE" "$MVOUT/$OUTNAME.mkv"
    rm -r "$TEMP/$TEMPFILE"
  fi

  # verify
  if [[ -n $( find "$MVOUT" -name "$MOVIENAME"* ) ]]; then
    sendToIRC "Movie Transfer Successful."
    sendToDiscord "New in Movies: $OUTNAME"
  else
    sendToIRC "Movie Transfer Failed." && exit
  fi

fi

sendToLog "Finished"
exit
