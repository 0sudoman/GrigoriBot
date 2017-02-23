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
#  sorted by air date
if [[ $DIR =~ "Gotham" ]]; then SHOW="Gotham"; fi
if [[ $DIR =~ "Shadowhunters" ]]; then SHOW="Shadowhunters"; fi
if [[ $DIR =~ "Jane.the.Virgin" ]]; then SHOW="Jane the Virgin"; fi
if [[ $DIR =~ "Scorpion" ]]; then SHOW="Scorpion"; fi

if [[ $DIR =~ "Brooklyn.Nine-Nine" ]]; then SHOW="Brooklyn Nine-Nine"; fi
if [[ $DIR =~ "New.Girl" ]]; then SHOW="New Girl"; fi
if [[ $DIR =~ "The.Flash" ]]; then SHOW="The Flash"; fi
if [[ $DIR =~ "The.Mick" ]]; then SHOW="The Mick"; fi
if [[ $DIR =~ "Bones" ]]; then SHOW="Bones"; fi
if [[ $DIR =~ "Bull" ]]; then SHOW="Bull (2016)"; fi
if [[ $DIR =~ "DCs.Legends" ]]; then SHOW="DC's Legends of Tomorrow"; fi
if [[ $DIR =~ "iZombie" ]]; then SHOW="iZombie"; fi
if [[ $DIR =~ "No.Tomorrow" ]]; then SHOW="No Tomorrow"; fi
if [[ $DIR =~ "Trial" ]]; then SHOW="Trail & Error"; fi
if [[ $DIR =~ "Marvels.Agents" ]]; then SHOW="Marvel's Agents of S.H.I.E.L.D"; fi
if [[ $DIR =~ "Taboo" ]]; then SHOW="Taboo (2017)"; fi
if [[ $DIR =~ "The.Expanse" ]]; then SHOW="The Expanse (2015)"; fi

if [[ $DIR =~ "Arrow" ]]; then SHOW="Arrow"; fi
if [[ $DIR =~ "Blindspot" ]]; then SHOW="Blindspot"; fi
if [[ $DIR =~ "Lethal.Weapon" ]]; then SHOW="Lethal Weapon"; fi
if [[ $DIR =~ "The.Goldbergs" ]]; then SHOW="The Goldbergs (2013)"; fi
if [[ $DIR =~ "The.100" ]]; then SHOW="The 100"; fi
if [[ $DIR =~ "The.Magicians" ]]; then SHOW="The Magicians (2015)"; fi
if [[ $DIR =~ "Designated.Survivor" ]]; then SHOW="Designated Survivor"; fi
if [[ $DIR =~ "Its.Always.Sunny" ]]; then SHOW="It's Always Sunny In Philadelphia"; fi
if [[ $DIR =~ "Legion" ]]; then SHOW="Legion"; fi
if [[ $DIR =~ "SIX.Part" ]]; then SHOW="Six"; fi #this one gets funky
if [[ $DIR =~ "Man.Seeking.Woman" ]]; then SHOW="Man Seeking Woman"; fi

if [[ $DIR =~ "Supernatural" ]]; then SHOW="Supernatural"; fi
if [[ $DIR =~ "The.Big.Bang.Theory" ]]; then SHOW="The Big Bang Theory"; fi
if [[ $DIR =~ "The.Good.Place" ]]; then SHOW="The Good Place"; fi
if [[ $DIR =~ "Powerless" ]]; then SHOW="Powerless"; fi

if [[ $DIR =~ "Grimm" ]]; then SHOW="Grimm"; fi
if [[ $DIR =~ "The.Grand.Tour" ]]; then SHOW="The Grand Tour"; fi

if [[ $DIR =~ "Bobs.Burgers" ]]; then SHOW="Bob's Burgers"; fi
if [[ $DIR =~ "Sherlock" ]]; then SHOW="Sherlock (2010)"; fi
if [[ $DIR =~ "Son.of.Zorn" ]]; then SHOW="Son of Zorn"; fi
if [[ $DIR =~ "Billions" ]]; then SHOW="Billions"; fi
if [[ $DIR =~ "Black.Sails" ]]; then SHOW="Black Sails"; fi
if [[ $DIR =~ "Homeland" ]]; then SHOW="Homeland"; fi
if [[ $DIR =~ "The.Last.Man.on.Earth" ]]; then SHOW="The Last Man on Earth"; fi
if [[ $DIR =~ "24.Legacy" ]]; then SHOW="24 Legacy"; fi
if [[ $DIR =~ "Elementary" ]]; then SHOW="Elementary"; fi
if [[ $DIR =~ "Last.Week.Tonight" ]]; then SHOW="Last Week Tonight with John Oliver"; fi

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
