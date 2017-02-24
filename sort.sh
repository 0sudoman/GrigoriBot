#!/bin/bash
# sort.sh
# sorts out TV shows and shit

source config.sh
echo "$( date ): sort.sh run" >> $LOGFILE

DIR="$1"
FORCE="false"
CHECK="false"
IRCOUT="true"
TRANSFER="true"
VERIFY="true"

SHOW="UNKNOWN"
SEASON="UNKNOWN"
EPISODE="UNKNOWN"
QUALITY="UNKNOWN"
TYPE="UNKNOWN"
EXIT="false"

# determine show name
#  improved algorithm
for SHOW in $FOUT/*; do
  if [[ "$SHOW" =~ .{${#FOUT}}.(.*)$ ]]; then SHOWNAME="${BASH_REMATCH[1]}"; fi
  if [[ "$SHOW" =~ .{${#FOUT}}.(.{1,13}) ]]; then SHOWMOD="${BASH_REMATCH[1]}"; fi
  SHOWMOD=${SHOWMOD/\ /\.} && SHOWMOD=${SHOWMOD/\ /\.} && SHOWMOD=${SHOWMOD/\ /\.}
  SHOWMOD=${SHOWMOD/\'/} && SHOWMOD=${SHOWMOD/\(/} && SHOWMOD=${SHOWMOD/\)/}
  if [[ $1 =~ ^"$SHOWMOD" ]]; then SHOW="$SHOWNAME"; break; fi
done

# determine season / episode
for i in $( seq -w 30 ); do if [[ "$DIR" =~ .*S$i.* ]]; then SEASON="$i"; fi; done
for i in $( seq -w 30 ); do if [[ "$DIR" =~ .*E$i.* ]]; then EPISODE="$i"; fi; done

# determine quality
if [[ $DIR =~ "HDTV" ]]; then QUALITY="SD"; fi
if [[ $DIR =~ "720p" ]]; then QUALITY="720p"; fi
if [[ $DIR =~ "1080p" ]]; then QUALITY="1080p"; fi;

# determine filetype
if [[ -n $( find "$FIN/$DIR" -name *.mkv ) ]]; then TYPE="mkv"; fi;
if [[ -n $( find "$FIN/$DIR" -name *.rar ) ]]; then TYPE="rar"; fi;

# concatenate target directory
TARGET="$FOUT/$SHOW/Season $SEASON/"

# see if assumptions make sense
OUTPUT="Transferring $SHOW S$SEASON E$EPISODE $QUALITY"
if [ $FORCE == false ]; then
  if [ "$SHOW" == "UNKNOWN" ] || [ $SEASON == "UNKNOWN" ] || [ $EPISODE == "UNKNOWN" ] || [ $TYPE == "UNKNOWN" ]; then 
    OUTPUT="Cannot find necessary data. Are you sure you entered a valid folder?"
    EXIT="true"
  fi
  if [[ -n $( find "$TARGET" -name *[Ee]$EPISODE* ) ]]; then
    OUTPUT="Target file already exists."
    EXIT="true"
  fi
fi
echo "$( date ): $OUTPUT" >> $LOGFILE
if [ $IRCOUT == true ]; then echo $OUTPUT > $IRC/in; fi
if [ $EXIT == true ]; then exit; fi

# ask for verification
if [ $CHECK == true ]; then
  echo "Transfer to $TARGET ?"
  while true; do
    read yn
    case $yn in
      [Yy]* ) break;;
      [Nn]* ) exit;;
      * ) echo "Please answer yes or no.";;
    esac
  done
fi

# extract/copy as needed
if [ $TRANSFER == true ]; then
  if [ $TYPE == mkv ]; then cp "$FIN/$DIR/*.mkv" "$TARGET"; fi
  if [ $TYPE == rar ]; then unrar e "$FIN/$DIR/*.rar" "$TARGET"; fi
fi

# verify file was copied
if [ $VERIFY == true ]; then
  if [[ -n $( find "$TARGET" -name *[Ee]$EPISODE* ) ]]; then
    OUTPUT="Transfer successful."
  else
    OUTPUT="Transfer failed."
  fi
  echo "$( date ): $OUTPUT" >> $LOGFILE
  if [ $IRCOUT == true ]; then echo $OUTPUT > $IRC/in; fi
fi

exit
