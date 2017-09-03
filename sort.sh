#!/bin/bash
# sort.sh
# sorts out TV shows and shit

source config.sh
SCRIPT="sort.sh"
sendToLog "Started"

args=("$@")

function get_input {
  # get input
  DIR="${args[0]}"
  sendToLog "Sorting $DIR"

  # set defaults
  SHOW="UNKNOWN"
  TYPE="UNKNOWN"
  QUALITY="UNKNOWN"
  CHECK=1
  TRANSFER=1
  VERIFY=1
}

function find_name {
  # determine show name (if it's a show)
  for FILE in $TVOUT/*; do
    if [[ "$FILE" =~ .{${#TVOUT}}.(.*)$ ]]; then SHOWNAME="${BASH_REMATCH[1]}"; fi
    if [[ "$FILE" =~ .{${#TVOUT}}.(.{1,13}) ]]; then SHOWMOD="${BASH_REMATCH[1]}"; fi
    for i in $( seq 5 ); do SHOWMOD=${SHOWMOD/\ /\.}; done
    SHOWMOD=${SHOWMOD/\'/} && SHOWMOD=${SHOWMOD/\(/} && SHOWMOD=${SHOWMOD/\)/}
    if [[ "${DIR,,}" =~ ^"${SHOWMOD,,}" ]]; then SHOW="$SHOWNAME"; break; fi
  done
  if [[ "$SHOW" != "UNKNOWN" ]]; then
    SORT="TV"
    sendToLog "Show matched: $SHOWNAME"
    # determine season & episode
    SEASON="UNKNOWN" && EPISODE="UNKNOWN"
    for i in $( seq -w 30 ); do if [[ "$DIR" =~ .*[Ss]$i.* ]]; then SEASON="$i"; fi; done
    for i in $( seq -w 30 ); do if [[ "$DIR" =~ .*[Ee]$i.* ]]; then EPISODE="$i"; fi; done
    if [ $SEASON == "UNKNOWN" ] || [ $EPISODE == "UNKNOWN" ]; then
      sendToIRC "$DIR Error [Season/Episode Error]"
      exit
    fi
    sendToLog "Season/Episode matched: S${SEASON}E${EPISODE}"

  else
    SORT="Movie"
    sendToLog "No TV show matched. Assuming it's a movie."
    # determine movie name and year
    if [[ $DIR =~ (.*).(19|20)([0-9]{2}) ]]; then
      MOVIENAME="${BASH_REMATCH[1]}"
      YEAR="${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
    else
      sendToLog "Could not find a year. It's probably not a movie."
      sendToIRC "$DIR Error [Name Error]"
      exit
    fi
    for i in $( seq 10 ); do MOVIENAME=${MOVIENAME/\./\ }; done
    sendToLog "Movie matched: $MOVIENAME [$YEAR]"
  fi
}

function find_type {
  # determine filetype
  if [[ -n $( find "$IN/$DIR" -name *.rar ) ]]; then TYPE="rar";
  elif [[ -n $( find "$IN/$DIR" -name *.mkv ) ]]; then TYPE="mkv";
  elif [[ -n $( find "$IN/$DIR" -name *.mp4 ) ]]; then TYPE="mp4";
  else
    sendToLog "Could not find a video file/archive. Are you sure the file exists?"
    sendToIRC "$DIR Error [Filetype Error]"
    exit
  fi
  sendToLog "Filetype matched: $TYPE"
}

function find_quality {
  # determine quality
  if [[ $DIR =~ "DVD[Ss][Cc][Rr]" ]] || [[ $DIR =~ "HC.HD[Rr][Ii][Pp]" ]] || [[ $DIR =~ "TS." ]]; then QUALITY="CAM"
  elif [[ $DIR =~ "720p" ]]; then QUALITY="720p"
  elif [[ $DIR =~ "1080p" ]]; then QUALITY="1080p"
  else
    sendToLog "Could not find a valid quality. Continuing anyways."
  fi
  sendToLog "Quality matched: $QUALITY"
}

function check_if_exists {
  # check for upgrades
  if [[ $SORT == "TV" ]]; then
    TARGET="$TVOUT/$SHOW/Season $SEASON/"
    if [[ -n $( find "$TARGET" -name *[Ee]$EPISODE* ) ]]; then
      sendToIRC "$DIR Error [Already Exists]"; exit
    fi

  else
    if [[ -n $( find "$MVOUT" -name "$MOVIENAME"* ) ]]; then
      if [[ -n $( find "$MVOUT" -name "$MOVIENAME"*CAM* ) ]] && [[ $QUALITY == "720p" ]] || [[ $QUALITY == "1080p" ]]; then
        sendToLog "Deleting CAM version to make way for $QuALITY version."
        sendToIRC "$DIR Notice [Upgrading]"
        rm "$MVOUT/$MOVIENAME"*CAM*
      elif [[ -n $( find "$MVOUT" -name "$MOVIENAME"*720p* ) ]] && [[ $QUALITY == "1080p" ]]; then
        sendToLog "Deleting 720p version to make way for $QUALITY version."
        sendToIRC "$DIR Notice [Upgrading]"
        rm "$MVOUT/$MOVIENAME"*720p*
      else
        sendToIRC "$DIR Error [Already Exists]"; exit
      fi
    fi
  fi
}

function transfer_file {
  # do the thing
  if [[ $SORT == "TV" ]]; then
    sendToLog "Transferring $SHOW S${SEASON}E${EPISODE} $QUALITY"
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

  else
    TARGET="$MVOUT"
    OUTNAME="$MOVIENAME [$YEAR] [$QUALITY]"
    sendToLog "Transferring Movie: $OUTNAME"
    if [[ $TYPE == mkv ]] || [[ $TYPE == mp4 ]]; then
      SOURCE="$IN/$DIR/$( ls -S $IN/$DIR | grep $TYPE | head -1 )"
      sendToLog "Copying '$SOURCE' to '$TARGET' as '$OUTNAME.mkv'"
      cp "$SOURCE" "$TARGET/$OUTNAME.$TYPE"
    fi
    if [[ $TYPE == rar ]]; then
      for i in $( seq 8 ); do TEMPFILE="${TEMPFILE}$(( RANDOM % 10 ))"; done
      sendToLog "Unraring '$IN/$DIR/*.rar' to '$TEMP/$TEMPFILE'"
      mkdir "$TEMP/$TEMPFILE"
      unrar e "$IN/$DIR/*.rar" "$TEMP/$TEMPFILE"
      SOURCE="$( ls -S $TEMP/$TEMPFILE | head -1 )"
      sendToLog "Moving '$SOURCE' to '$TARGET' as '$OUTNAME.mkv'"
      mv "$TEMP/$TEMPFILE/$SOURCE" "$TARGET/$OUTNAME.mkv"
      rm -r "$TEMP/$TEMPFILE"
    fi
  fi
}

function verify_transfer {
  # see if the thing was done
  if [[ $SORT == "TV" ]]; then
    if [[ -n $( find "$TARGET" -name *[Ee]$EPISODE* ) ]]; then
      sendToIRC "$SHOW S${SEASON}E${EPISODE} Transferred successfully."
      sendToDiscord "New in TV: $SHOW S${SEASON}E${EPISODE}"
    else
      sendToIRC "$DIR Error [Transfer Failed]" && exit
    fi
  else
    if [[ -n $( find "$MVOUT" -name "$MOVIENAME"* ) ]]; then
      sendToIRC "$OUTNAME Transferred Successfully."
      sendToDiscord "New in Movies: $OUTNAME"
    else
      sendToIRC "$DIR Error [Transfer Failed]" && exit
    fi
  fi
}


# main function
get_input
if [[ "$SHOW" == "UNKNOWN" ]]; then find_name; fi
if [[ "$TYPE" == "UNKNOWN" ]]; then find_type; fi
if [[ "$QUALITY" == "UNKNOWN" ]]; then find_quality; fi
if [[ $CHECK == 1 ]]; then check_if_exists; fi
if [[ $TRANSFER == 1 ]]; then transfer_file; fi
if [[ $VERIFY == 1 ]]; then verify_transfer; fi

sendToLog "Finished"

exit
