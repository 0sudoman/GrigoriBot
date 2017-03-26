#!/bin/bash
# sort.sh
# sorts out TV shows and shit

source config.sh
SCRIPT="sort.sh"
sendToLog "Started"
DIR="$1"

# determine show name
for SHOW in $TVOUT/*; do
  if [[ "$SHOW" =~ .{${#TVOUT}}.(.*)$ ]]; then SHOWNAME="${BASH_REMATCH[1]}"; fi
  if [[ "$SHOW" =~ .{${#TVOUT}}.(.{1,13}) ]]; then SHOWMOD="${BASH_REMATCH[1]}"; fi
  for i in $( seq 5 ); do SHOWMOD=${SHOWMOD/\ /\.}; done
  SHOWMOD=${SHOWMOD/\'/} && SHOWMOD=${SHOWMOD/\(/} && SHOWMOD=${SHOWMOD/\)/}
  if [[ "$DIR" =~ ^"$SHOWMOD" ]]; then SHOW="$SHOWNAME"; SORT="TV"; sendToLog "Show matched: $SHOWNAME"; break; fi
done

# determine filetype & quality
if [[ -n $( find "$IN/$DIR" -name *.rar ) ]]; then TYPE="rar";
elif [[ -n $( find "$IN/$DIR" -name *.mkv ) ]]; then TYPE="mkv";
elif [[ -n $( find "$IN/$DIR" -name *.mp4 ) ]]; then TYPE="mp4";
else sendToIRC "Could not find necessary data [filetype]. Terminating."; exit; fi
sendToLog "Filetype matched: $TYPE"

if [[ $DIR =~ "DVD[Ss][Cc][Rr]" ]]; then QUALITY="CAM"
elif [[ $DIR =~ "720p" ]]; then QUALITY="720p"
elif [[ $DIR =~ "1080p" ]]; then QUALITY="1080p"
else sendToIRC "Could not find necessary data [quality]. Terminating."; exit; fi
sendToLog "Quality matched: $QUALITY"

if [[ $SORT == "TV" ]]; then
  # determine season & episode
  SEASON="UNKNOWN" && EPISODE="UNKNOWN"
  for i in $( seq -w 30 ); do if [[ "$DIR" =~ .*[Ss]$i.* ]]; then SEASON="$i"; fi; done
  for i in $( seq -w 30 ); do if [[ "$DIR" =~ .*[Ee]$i.* ]]; then EPISODE="$i"; fi; done
  if [ $SEASON == "UNKNOWN" ] || [ $EPISODE == "UNKNOWN" ]; then sendToIRC "Could not find necessary data [season/episode]. Terminating."; exit; fi
  sendToLog "Season/Episode matched: S${SEASON}E${EPISODE}"

  # check for upgrades
  TARGET="$TVOUT/$SHOW/Season $SEASON/"
  if [[ -n $( find "$TARGET" -name *[Ee]$EPISODE* ) ]]; then
    sendToIRC "Target file already exists. Terminating."; exit
  fi

  # transfer
  sendToIRC "Transferring $SHOW S${SEASON}E${EPISODE} $QUALITY"
  if [[ $TYPE == mkv ]] || [[ $TYPE == mp4 ]]; then
    SOURCE="$IN/$DIR/$( ls -S $IN/$DIR | grep $TYPE | head -1 )"
    sendToLog "Copying '$SOURCE' to '$TARGET'"
    cp "$SOURCE" "$TARGET"
  fi
  if [[ $TYPE == rar ]]; then
    SOURCE="$IN/$DIR/$( ls -S $IN/$DIR | grep $TYPE | head -1 )"
    sendToLog "Unraring '$SOURCE' to '$TARGET'"
    unrar e "$SOURCE" "$TARGET"
  fi

  # verify
  if [[ -n $( find "$TARGET" -name *[Ee]$EPISODE* ) ]]; then
    sendToIRC "TV Transfer Successful."
    sendToDiscord "New in TV: $SHOW S${SEASON}E${EPISODE}"
  else
    sendToIRC "TV Transfer Failed." && exit
  fi
else
  # determine movie name and year
  if [[ $DIR =~ (.*).(19|20)([0-9]{2}) ]]; then MOVIENAME="${BASH_REMATCH[1]}"; YEAR="${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; else sendToIRC "Could not find necessary data [name/year]. Terminating."; exit; fi
  for i in $( seq 10 ); do MOVIENAME=${MOVIENAME/\./\ }; done
  sendToLog "Movie matched: $MOVIENAME [$YEAR]"

  # check for upgrades
  if [[ -n $( find "$MVOUT" -name "$MOVIENAME"* ) ]]; then
    if [[ -n $( find "$MVOUT" -name "$MOVIENAME"*CAM* ) ]] && [[ $QUALITY != "CAM" ]]; then
      sendToIRC "Target file already exists, but it's a cam. Upgrading to $QUALITY."
      rm "$MVOUT/$MOVIENAME"*CAM*
    elif [[ -n $( find "$MVOUT" -name "$MOVIENAME"*720p* ) ]] && [[ $QUALITY == "1080p" ]]; then
      sendToIRC "Target file already exists, but it's only 720p. Upgrading to $QUALITY."
      rm "$MVOUT/$MOVIENAME"*720p*
    else
      sendToIRC "Target file already exists. Terminating."; exit
    fi
  fi

  # transfer
  TARGET="$MVOUT"
  OUTNAME="$MOVIENAME [$YEAR] [$QUALITY]"
  sendToIRC "Transferring Movie: $OUTNAME"
  if [[ $TYPE == mkv ]] || [[ $TYPE == mp4 ]]; then
    SOURCE="$IN/$DIR/$( ls -S $IN/$DIR | grep $TYPE | head -1 )"
    sendToLog "Copying '$SOURCE' to '$TARGET'"
    cp "$SOURCE" "$TARGET/$OUTNAME.$TYPE"
  fi
  if [[ $TYPE == rar ]]; then
    for i in $( seq 8 ); do TEMPFILE="${TEMPFILE}$(( RANDOM % 10 ))"; done
    sendToLog "Unraring '$IN/$DIR/*.rar' to '$TEMP/$TEMPFILE'"
    mkdir "$TEMP/$TEMPFILE"
    unrar e "$IN/$DIR/*.rar" "$TEMP/$TEMPFILE"
    SOURCE="$( ls -S $TEMP/$TEMPFILE | head -1 )"
    sendToLog "Copying '$SOURCE' to '$TARGET' as '$OUTNAME.mkv'"
    mv "$TEMP/$TEMPFILE/$SOURCE" "$TARGET/$OUTNAME.mkv"
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
