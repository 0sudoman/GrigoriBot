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
  else
    SORT="Movie"
    sendToLog "No TV show matched. Assuming it's a movie."
    # determine movie name and year
    if [[ $DIR =~ (.*).(19|20)([0-9]{2}) ]]; then
      MOVIENAME="${BASH_REMATCH[1]}"
      YEAR="${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
    else
      sendToIRC "Could not find necessary data [name/year]. Terminating."
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
    sendToIRC "Could not find necessary data [filetype]. Terminating."
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
    sendToIRC "Could not find necessary data [quality]. Terminating."
    exit
  fi
  sendToLog "Quality matched: $QUALITY"
}

function check_if_exists {
  # check for upgrades
  if [[ $SORT == "TV" ]]; then
    TARGET="$TVOUT/$SHOW/Season $SEASON/"
    if [[ -n $( find "$TARGET" -name *[Ee]$EPISODE* ) ]]; then
      sendToIRC "Target file already exists. Terminating."; exit
    fi

  else
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
  fi
}

function transfer_file {
  #do the thing
  if [[ $SORT == "TV" ]]; then
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

  else
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
  fi
}

function verify_transfer {
  # see if the thing was done
  if [[ $SORT == "TV" ]]; then
    if [[ -n $( find "$TARGET" -name *[Ee]$EPISODE* ) ]]; then
      sendToIRC "TV Transfer Successful."
      sendToDiscord "New in TV: $SHOW S${SEASON}E${EPISODE}"
    else
      sendToIRC "TV Transfer Failed." && exit
    fi
  else
    if [[ -n $( find "$MVOUT" -name "$MOVIENAME"* ) ]]; then
      sendToIRC "Movie Transfer Successful."
      sendToDiscord "New in Movies: $OUTNAME"
    else
      sendToIRC "Movie Transfer Failed." && exit
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
