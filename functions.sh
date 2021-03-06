#!/bin/bash
# functions.sh
# I got tired of having local functions

# PRECURSOR FUNCTIONS
function resetVariables {
  id="XXXX"

  movieOrTV=-1
  folderOrFile=-1
  fileType=-1

  movieName=-1
  movieYear=-1
  movieQuality=-1

  tvStyle=-1
  tvName=-1
  tvSeason=-1
  tvEpisode=-1
  tvYear=-1
  tvDate=-1

  isInDB=-1
  sortError=-1
}

function doDbQuery {
  #logInfo " Query Input: $dbQuery"
  dbResult="$( $dbCommand "$dbQuery" 2>/dev/null )"
  #if [[ "$dbResult" == "" ]]; then
    #logInfo " Empty response from database." #perfectly normal
    #logError "Error 22 [Database Connection Error]"
    #sortError=22
  #else
    #logInfo " Query Result: $dbResult"
  #fi
}

function doDbQueryP {
  # This version tries seeral times to get a response
  # ONLY USE WHEN A RESPONSE IS ALMOST GUARANTEED
  dbResult="$( $dbCommand "$dbQuery" 2>/dev/null )"
  if [[ "$dbResult" == "" ]]; then

    # Fail #1
    dbResult="$( $dbCommand "$dbQuery" 2>/dev/null )"
    if [[ "$dbResult" == "" ]]; then

      # Fail #2
      dbResult="$( $dbCommand "$dbQuery" 2>/dev/null )"
      if [[ "$dbResult" == "" ]]; then

        # Fail #3
        logInfo " Empty response from database."
        pingServer
        if [[ $sortError != -1 ]]; then
          logWarn " Server Connect Error. Retrying in 30 seconds..."
          sortError=-1
          sleep 30
          doDbQuery
        fi

      fi
    fi
  fi
}

# STARTUP FUNCTIONS
function pingServer {
  logInfo "Pinging Server..."

  ping -c1 "$dbHostname" > /dev/null
  if [[ $? == 0 ]]; then
    logInfo " Server ping successful."
  else
    logWarn " Server is probably down."
    logError "Error 21 [Server Disconnect]"
    sortError=21
  fi
}

function getSettings {
  logInfo "Getting Settings..."

  for i in sortDefault sortWaitTime; do
    dbQuery="SELECT value FROM $dbSettings WHERE setting='$i'"
    doDbQueryP
    declare -g $i="$dbResult"
    logInfo " $i: ${!i}"
  done

  if [[ sortDefault != "" && sortWaitTime != "" ]]; then
    logInfo " Settings acquired."
  else
    logWarn " Could not get settings from database."
    logError "Error 23 [Database Read Error]"
    sortError=23
  fi
}

# ITERATIVE FUNCTIONS
function fixSortInput {
  #logInfo "Cleaning Sort Input..."

  if [[ "$sortInputRaw" =~ .{${#sortDir}}.(.*)$ ]]; then
    sortInput="${BASH_REMATCH[1]}"
    #logInfo " Sort Input Cleaned."
    #logInfo " sortInput: $sortInput"
  else
    logWarn " Could not clean sort input."
    logError "Error 12 [File Error] $sortInputRaw"
    sortError=12
  fi
}

function getDbInfoID {
  logInfo "Getting ID..."
  dbQuery="SELECT id FROM $dbList WHERE sortInput=\"$sortInput\""
  id="XXXX"
  doDbQueryP
  id="$dbResult"

  if [[ "$id" != "" ]]; then
    isInDB=1
    logInfo " id: $id"
  else
    isInDB=0
    id="XXXX"
    logInfo " Could not find information in database."
  fi
}

function getDbInfoPotential {
  logInfo "Getting Preliminary Database Info [Potential]..."
  dbQuery="SELECT sortPotential FROM $dbList WHERE id=$id"
  doDbQuery
  sortPotential="$dbResult"
  if [[ $sortPotential == "NULL" ]] || [[ $sortPotential == "" ]]; then sortPotential=$sortDefault; fi
  logInfo " sortPotential: $sortPotential"
}

function getDbInfoComplete {
  logInfo "Getting Preliminary Database Info [Complete]..."
  dbQuery="SELECT sortComplete FROM $dbList WHERE id=$id"
  doDbQuery
  sortComplete="$dbResult"
  logInfo " sortComplete: $sortComplete"
}

function getDbInfoError {
  logInfo "Getting Preliminary Database Info [Error]..."
  dbQuery="SELECT sortError FROM $dbList WHERE id=$id"
  doDbQuery
  sortError="$dbResult"
  if [[ $sortError == "NULL" ]]; then sortError=-1; fi
  logInfo " sortError: $sortError"
}

function getDbInfo {
  logInfo "Getting Database Info..."

  for i in \
    movieOrTV \
    folderOrFile \
    fileType \
    movieName \
    movieYear \
    movieQuality \
    tvStyle \
    tvName \
    tvSeason \
    tvEpisode \
    tvYear \
    tvDate
  do
    dbQuery="SELECT $i FROM $dbList WHERE id=$id"
    doDbQuery
    declare -g $i="$dbResult"
    logInfo " $i: ${!i}"
  done

  logInfo "Information Downloaded."
  # I have no way of knowing if this worked...
}

function getTimeSinceModify {
  logInfo "Getting time since last modification..."

  timeSinceModify=$(( $( date +%s ) - $( date -r "$sortDir/$sortInput" +%s ) ))
  if [[ $timeSinceModify -ge 0 ]]; then
    logInfo " Modification time acquired."
    logInfo " timeSinceModify: $timeSinceModify"
    logInfo " sortWaitTime: $sortWaitTime"
  else
    logWarn " Could not get modification time."
    logError "Error 12 [File Read Error] $sortInput"
    sortError=12
  fi
}

# PARSE FUNCTIONS
function findFileType {
  logInfo "Finding Filetype..."

  if [[ -n $( find "$sortDir/$sortInput" -name "*.rar" ) ]]; then fileType="rar";
  elif [[ -n $( find "$sortDir/$sortInput" -name "*.mkv" ) ]]; then fileType="mkv";
  elif [[ -n $( find "$sortDir/$sortInput" -name "*.mp4" ) ]]; then fileType="mp4";
  elif [[ -n $( find "$sortDir/$sortInput" -name "*.avi" ) ]]; then fileType="avi";
  else
    logWarn " Could not find a video file/archive. Are you sure the file exists?"
    #logError "Error 34 [Filetype Error] $sortInput"
    sortError=34
  fi

  if [[ "$fileType" != -1 ]]; then
    logInfo " Filetype matched: $fileType"
  fi
}

function findFolderOrFile {
  logInfo "Finding Folder/File Status..."

  if [[ $sortInput =~ $fileType ]]; then
    folderOrFile=2
    logInfo " Folder/File Status: File"
  else
    folderOrFile=1
    logInfo " Folder/File Status: Folder"
  fi
}

function findMovieOrTV {
  logInfo "Finding Movie/TV Status..."

  inputMod=$sortInput
  for sampleFile in "$tvDir"/*; do
    if [[ "$sampleFile" =~ .{${#tvDir}}.(.*)$ ]]; then tvNameTest="${BASH_REMATCH[1]}"; fi
    if [[ "$sampleFile" =~ .{${#tvDir}}.(.{1,24}) ]]; then sampleMod="${BASH_REMATCH[1]}"; fi
    sampleMod=${sampleMod/\(/} && sampleMod=${sampleMod/\)/} # remove parentheses
    sampleMod=${sampleMod//\./}    # remove dots
    sampleMod=${sampleMod/\,/}     # remove commas
    sampleMod=${sampleMod/\!/}     # remove bangs
    sampleMod=${sampleMod/\'/}     # remove apostrophes (sample)
    inputMod=${inputMod/\'/}       # remove apostrophes (imput)
    inputMod=${inputMod/_/}        # remove underscores
    sampleMod=${sampleMod//\ /\.}  # convert spaces to dots
    if [[ "${inputMod,,}" =~ ^"${sampleMod,,}" ]]; then
      tvName="$tvNameTest"
      break
    fi
  done

  if [[ "$tvName" != -1 ]]; then
    movieOrTV=2
    logInfo " Movie/TV Status: TV"
    logInfo " Show matched: $tvName"
  else
    movieOrTV=1
    logInfo " No TV Show found."
  fi
}

function findMovieData {
  logInfo "Finding Movie Information..."

  if [[ "$sortInput" =~ (.*).(19|20)([0-9]{2}) ]]; then
    movieName="${BASH_REMATCH[1]}"
    movieYear="${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
    for i in $( seq 10 ); do movieName=${movieName/\./\ }; done
    logInfo " Movie/TV Status: Movie"
    logInfo " Movie matched: $movieName [$movieYear]"
  else
    movieOrTV=3
    logWarn " Could not find a year. It's probably not a movie."
    #logError "Error 32 [Movie Data Error] $sortInput"
    sortError=32
  fi
}

function findMovieQuality {
  logInfo "Finding Movie Quality..."

  if [[ ${sortInput,,} =~ "dvdscr" ]] || \
    [[ ${sortInput,,} =~ "sub" ]] || \
    [[ ${sortInput,,} =~ "blurred" ]] || \
    [[ ${sortInput,,} =~ "cam" ]] || \
    [[ ${sortInput,,} =~ "tc" ]] || \
    [[ ${sortInput,,} =~ "hc" ]]
    then movieQuality="CAM"
  elif [[ $sortInput =~ "720p" ]]; then movieQuality="720p"
  elif [[ $sortInput =~ "1080p" ]]; then movieQuality="1080p"
  elif [[ $sortInput =~ "2160p" ]]; then movieQuality="2160p"
  else
    logWarn " Could not find a valid quality."
    #logError "Error 33 [Movie Quality Error] $sortInput"
    movieQuality="UNKNOWN"
    movieOrTV=3
    sortError=33
  fi

  logInfo " Quality matched: $movieQuality"
}

function findTvData {
  logInfo "Finding TV Data..."

  if [[ $sortInput =~ (.*).(19|20)([0-9]{2}).([0-9]{2}).([0-9]{2}) ]]; then
    tvYear="${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
    tvDate="${BASH_REMATCH[2]}${BASH_REMATCH[3]}.${BASH_REMATCH[4]}.${BASH_REMATCH[5]}"
    tvStyle=2
    logInfo " TV Style: YYYY.MM.DD (2)"
    logInfo " TV Year: $tvYear"
    logInfo " TV Date: $tvDate"
  else
    for i in $( seq -w 99 ); do if [[ "$sortInput" =~ .*[Ss]$i.* ]]; then tvSeason="$i"; fi; done
    for i in $( seq -w 99 ); do if [[ "$sortInput" =~ .*[Ee]$i.* ]]; then tvEpisode="$i"; fi; done
    if [[ $tvSeason != -1 && $tvEpisode != -1 ]]; then
      tvStyle=1
      logInfo " TV Style: SXXEXX (1)"
      logInfo " TV Season: $tvSeason"
      logInfo " TV Episode: $tvEpisode"
    else
      logWarn " Could not find TV Data."
      #logError "Error 31 [TV Data Error] $sortInput"
      movieOrTV=3
      sortError=31
    fi
  fi
}

function uploadDataMovie {
  logInfo "Uploading Information to Database..."

  dbQuery="INSERT INTO sortList (sortInput, movieOrTV, folderOrFile, fileType, movieName, movieYear, movieQuality, sortPotential) VALUES (\"$sortInput\", \"1\", \"$folderOrFile\", \"$fileType\", \"$movieName\", \"$movieYear\", \"$movieQuality\", \"$sortPotential\")"
  doDbQuery

  dbQuery="SELECT id FROM $dbList WHERE sortInput=\"$sortInput\""
  doDbQuery
  if [[ "$dbResult" != "" ]]; then
    logInfo " Information uploaded succeessfully."
  else
    logWarn " Could not insert row to database."
    logError "Error 24 [Database Write Error]"
    sortError=24
  fi
}

function uploadDataTV1 {
  logInfo "Uploading Information to Database..."

  dbQuery="INSERT INTO sortList (sortInput, movieOrTV, folderOrFile, fileType, tvStyle, tvName, tvSeason, tvEpisode, sortPotential) VALUES (\"$sortInput\", \"$movieOrTV\", \"$folderOrFile\", \"$fileType\", \"$tvStyle\", \"$tvName\", \"$tvSeason\", \"$tvEpisode\", \"$sortPotential\")"
  doDbQuery

  dbQuery="SELECT id FROM $dbList WHERE sortInput=\"$sortInput\""
  doDbQuery
  if [[ "$dbResult" != "" ]]; then
    logInfo " Information uploaded succeessfully."
  else
    logWarn " Could not insert row to database."
    logError "Error 24 [Database Write Error]"
    sortError=24
  fi
}

function uploadDataTV2 {
  logInfo "Uploading Information to Database..."

  dbQuery="INSERT INTO sortList (sortInput, movieOrTV, folderOrFile, fileType, tvStyle, tvName, tvYear, tvDate, sortPotential) VALUES (\"$sortInput\", \"$movieOrTV\", \"$folderOrFile\", \"$fileType\", \"$tvStyle\", \"$tvName\", \"$tvYear\", \"$tvDate\", \"$sortPotential\")"
  doDbQuery

  dbQuery="SELECT id FROM $dbList WHERE sortInput=\"$sortInput\""
  doDbQuery
  if [[ "$dbResult" != "" ]]; then
    logInfo " Information uploaded succeessfully."
  else
    logWarn " Could not insert row to database."
    logError "Error 24 [Database Write Error]"
    sortError=24
  fi
}

function uploadDataOther {
  logInfo "Uploading Information to Database..."

  dbQuery="INSERT INTO sortList (sortInput, movieOrTV, folderOrFile, fileType, sortPotential) VALUES (\"$sortInput\", \"$movieOrTV\", \"$folderOrFile\", \"$fileType\", \"$sortPotential\")"
  doDbQuery

  dbQuery="SELECT id FROM $dbList WHERE sortInput=\"$sortInput\""
  doDbQuery
  if [[ "$dbResult" != "" ]]; then
    logInfo " Information uploaded succeessfully."
  else
    logWarn " Could not insert row to database."
    logError "Error 24 [Database Write Error]"
    sortError=24
  fi
}

# SORT FUNCTIONS
function seeIfExistsMovie {
  logInfo "Finding Movie..."

  if [[ -n $( find "$movieDir" -iname "${movieName}*${movieYear}"* ) ]]; then
    if [[ -n $( find "$movieDir" -iname "${movieName}*${movieYear}*CAM*" ) ]] && [[ $movieQuality == "720p" || $movieQuality == "1080p" ]]; then
      logWarn " Deleting CAM version to make way for $movieQuality version."
      rm "$movieDir"/"$movieName"*"$movieYear"*CAM*
    elif [[ -n $( find "$movieDir" -iname "${movieName}*${movieYear}*720p*" ) ]] && [[ $movieQuality == "1080p" ]]; then
      logWarn " Deleting 720p version to make way for $movieQuality version."
      rm "$movieDir"/"$movieName"*"$movieYear"*720p*
    else
      logWarn "Movie already exists."
      #logError "Error 46 [Movie Already Exists] $sortInput"
      sortError=46
    fi
  else
    logInfo " Movie does not already exist. Proceeding."
  fi
}

function seeIfExistsTV1 {
  logInfo "Finding Episode..."

  if [[ -n $( find "$tvDir/$tvName/Season $tvSeason" -name "*[Ee]${tvEpisode}*" 2> /dev/null ) ]]; then
    if [[ $sortInput =~ "PROPER" ]] || [[ $sortInput =~ "REPACK" ]]; then
      logWarn " Deleting old version to make way for a new one."
      rm "$tvDir/$tvName/Season $tvSeason/"*E$tvEpisode*
    else
      logWarn "Episode already exists."
      #logError "Error 45 [Episode Already Exists] $sortInput"
      sortError=45
    fi
  else
    logInfo " Episode does not already exist. Proceeding."
  fi
}

function seeIfExistsTV2 {
  logInfo "Finding Episode..."

  if [[ -n $( find "$tvDir/$tvName/Season $tvYear" -name "*${tvDate}*" 2> /dev/null ) ]]; then
    logWarn "Episode already exists."
    #logError "Error 45 [Episode Already Exists] $sortInput"
    sortError=45
  else
    logInfo " Episode does not already exist. Proceeding."
  fi
}

function sortMovie {
  logInfo "Sorting Movie..."

  movieFullname="$movieName [$movieYear] [$movieQuality]"
  if [[ $fileType == mkv ]] || [[ $fileType == mp4 ]] || [[ $fileType == avi ]]; then
    if [[ $folderOrFile == 1 ]]; then
      movieSource="$sortDir/$sortInput/$( ls -S "$sortDir/$sortInput" | grep $fileType | head -1 )"
      movieTarget="$movieDir/$movieFullname.$fileType"

      logInfo " Copying '$movieSource' to '$movieTarget'"
      cp "$movieSource" "$movieTarget"

    elif [[ $folderOrFile == 2 ]]; then
      movieSource="$sortDir/$sortInput"
      movieTarget="$movieDir/$movieFullname.$fileType"

      logInfo " Copying '$movieSource' to '$movieTarget'"
      cp "$movieSource" "$movieTarget"

    fi
  elif [[ $fileType == rar ]]; then
    tempDirActive="$tempDir/"
    for i in $( seq 8 ); do tempDirActive="${tempDirActive}$(( RANDOM % 10 ))"; done
    movieSourceRar="$sortDir/$sortInput"
    movieTarget="$movieDir/$movieFullname.mkv"

    logInfo " Unraring '$movieSourceRar' archives to '$tempDirActive'"
    mkdir "$tempDirActive"
    unrar e "$movieSourceRar/*.rar" "$tempDirActive" > /dev/null

    movieSource="$tempDirActive/$( ls -S $tempDirActive | head -1 )"

    logInfo " Moving '$movieSource' to '$movieTarget'"
    mv "$movieSource" "$movieTarget"
    rm -r "$tempDirActive"

  fi
  logInfo " Transfer complete."
}

function sortTV1 {
  logInfo "Sorting Episode..."

  if [[ $fileType == mkv ]] || [[ $fileType == mp4 ]] || [[ $fileType == avi ]]; then
    if [[ $folderOrFile == 1 ]]; then

      tvSource="$sortDir/$sortInput/$( ls -S $sortDir/$sortInput | grep $fileType | head -1 )"
      tvTarget="$tvDir/$tvName/Season $tvSeason/"

      logInfo " Copying '$tvSource' to '$tvTarget'"

      if [[ "$tvEpisode" == "01" ]]; then mkdir "$tvTarget" > /dev/null; fi
      cp "$tvSource" "$tvTarget"

    elif [[ $folderOrFile == 2 ]]; then

      tvSource="$sortDir/$sortInput"
      tvTarget="$tvDir/$tvName/Season $tvSeason/"

      logInfo " Copying '$tvSource' to '$tvTarget'"

      if [[ "$tvEpisode" == "01" ]]; then mkdir "$tvTarget" > /dev/null; fi
      cp "$tvSource" "$tvTarget"

    fi
  elif [[ $fileType == rar ]]; then
    tvSourceRar="$sortDir/$sortInput"
    tvTarget="$tvDir/$tvName/Season $tvSeason/"
    logInfo " Unraring '$tvSourceRar' archives to '$tvTarget'"

    unrar e "$tvSourceRar/*.rar" "$tvTarget" > /dev/null

  fi

  logInfo " Transfer complete."
}

function sortTV2 {
  logInfo "Sorting Episode..."
  if [[ $tvDate =~ "\.01\.0" ]]; then
    mkdir "$tvDir/$tvName/Season $tvYear/"
  fi
  if [[ $fileType == mkv ]] || [[ $fileType == mp4 ]] || [[ $fileType == avi ]]; then
    if [[ $folderOrFile == 1 ]]; then
      tvSource="$sortDir/$sortInput/$( ls -S $sortDir/$sortInput | grep $fileType | head -1 )"
      tvTarget="$tvDir/$tvName/Season $tvYear/"
      logInfo " Copying '$tvSource' to '$tvTarget'"
      cp "$tvSource" "$tvTarget"
    elif [[ $folderOrFile == 2 ]]; then
      tvSource="$sortDir/$sortInput"
      tvTarget="$tvDir/$tvName/Season $tvYear/"
      logInfo " Copying '$tvSource' to '$tvTarget'"
      cp "$tvSource" "$tvTarget"
    fi
  elif [[ $fileType == rar ]]; then
    tvSourceRar="$sortDir/$sortInput"
    tvTarget="$tvDir/$tvName/Season $tvYear"
    logInfo " Unraring '$tvSourceRar' archives to '$tvTarget'"
    unrar e "$tvSourceRar/*.rar" "$tvTarget" > /dev/null
  fi
  logInfo " Transfer complete."
}

# VERIFY FUNCTIONS
function verifyMovie {
  logInfo "Finding Movie..."
  if [[ -n $( find "$movieDir" -iname "${movieName}*" ) ]]; then
    logInfo " Movie transferred successfully"
    logSuccess "New Movie: $movieFullname"
  else
    logWarn " Movie was not found."
    logError "Error 48 [Movie Transfer Error] $sortInput"
    sortError=48
  fi
}

function verifyTV1 {
  logInfo "Finding Episode..."
  if [[ -n $( find "$tvDir/$tvName/Season $tvSeason" -name "*[Ee]${tvEpisode}*" 2> /dev/null ) ]]; then
    logInfo " Episode transferred successfully"
    logSuccess "New TV: $tvName S${tvSeason}E${tvEpisode}"
  else
    logWarn " Episode was not found."
    logError "Error 47 [TV Transfer Error] $sortInput"
    sortError=47
  fi
}

function verifyTV2 {
  logInfo "Finding Episode..."
  if [[ -n $( find "$tvDir/$tvName/Season $tvYear" -name "*${tvDate}*" 2> /dev/null ) ]]; then
    logInfo " Episode transferred successfully"
    logSuccess "New TV: $tvName $tvDate"
  else
    logWarn " Episode was not found."
    logError "Error 47 [TV Transfer Error] $sortInput"
    sortError=47
  fi
}

function updateInfoSuccess {
  logInfo "Updating Information in Database..."

  dbQuery="UPDATE $dbList SET sortComplete = 1 WHERE id=\"$id\""
  doDbQuery
  dbQuery="SELECT sortComplete FROM $dbList WHERE id=\"$id\""
  doDbQuery
  if [[ "$dbResult" == 1 ]]; then
    logInfo " Status updated succeessfully."
  else
    logWarn " Could not update database."
    logError "Error 25 [Database Modify Error]"
    sortError=25
  fi
}

function updateInfoFailure {
  logInfo "Updating Information in Database..."

  dbQuery="UPDATE $dbList SET sortError = \"$sortError\" WHERE id=\"$id\""
  doDbQuery
  dbQuery="SELECT sortError FROM $dbList WHERE id=\"$id\""
  doDbQuery
  if [[ "$dbResult" != "NULL" ]]; then
    logInfo " Status updated succeessfully."
  else
    logWarn " Could not update database."
    logError "Error 25 [Database Modify Error]"
    sortError=25
  fi
}

# AUTOSORT FUNCTIONS
# thanks for the idea Vanilla
function autosortStart {
  if [[ -n $( find "$botDir/autosort.lock" 2> /dev/null ) ]]; then
    logWarn "Lock file found. Autosort is still running or did not shut down properly."
    logError "Error 16 [Lock File Exists]"
    exit
  else
    touch "$botDir/autosort.lock"
    if [[ -n $( find "$botDir/autosort.lock" 2> /dev/null ) ]]; then
      logInfo "Lock file created."
    else
      logWarn "Lock file could not be created."
      logError "Error 14 [Lock File Write Error]"
      exit
    fi
  fi
}

function autosortExit {
  if [[ -n $( find "$botDir/autosort.lock" 2> /dev/null ) ]]; then
    logInfo "Removing lock file..."
    rm "$botDir/autosort.lock"
    if [[ -n $( find "$botDir/autosort.lock" 2> /dev/null ) ]]; then
      logWarn "Could not remove lock file."
      logWarn "You will probably not be able to start this script until you delete it."
      logError "Error 15 [Lock File Delete Error]"
    else
      logInfo "Lock file removed."
    fi
  else
    logWarn "Lock file was not found."
    logInfo "It's strange, but not impossible."
  fi

  logInfo "Exiting."
  exit
}
