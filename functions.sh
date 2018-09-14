#!/bin/bash
# functions.sh
# I got tired of having local functions

# DATABASE FUNCTIONS
function resetVariables {
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
  error=-1
}

function pingServer {
  logInfo "Pinging Server..."
  ping -c1 "$dbHostname" > /dev/null
  if [[ $? == 0 ]]; then
    logInfo " Server ping successful."
  else
    logWarn " Server is probably down."
    logError "Error 21 [Server Disconnect]"
    error=21
  fi
}

function doDbQuery {
  #logInfo "Querying Database..."
  #logInfo " Query Input: $dbQuery"
  dbResult="$( $dbCommand "$dbQuery" 2>/dev/null )"
  if [[ "$dbResult" == "" ]]; then
    logInfo " Empty response from database." #perfectly normal
    #logError "Error 22 [Database Connection Error]"
    #error=22
  #else
    #logInfo " Query Result: $dbResult"
  fi
}

function getSettings {
  logInfo "Getting Settings..."
  dbQuery="SELECT * FROM $dbSettings WHERE id=1"
  doDbQuery
  if [[ "$dbResult" =~ ^1([^0-9]*)([0-1])([^0-9]*)([0-9]*)$ ]]; then
    sortDefault="${BASH_REMATCH[2]}"
    sortWaitTime="${BASH_REMATCH[4]}"
    logInfo " Settings acquired."
    logInfo " sortDefault: $sortDefault"
    logInfo " sortWaitTime: $sortWaitTime"
  else
    logWarn " Could not get settings from database."
    logError "Error 23 [Database Read Error]"
    error=23
  fi
}

function fixSortInput {
  logInfo "Cleaning Sort Input..."
  if [[ "$sortInputRaw" =~ .{${#sortDir}}.(.*)$ ]]; then
    sortInput="${BASH_REMATCH[1]}"
    logInfo " Sort Input Cleaned."
    logInfo " sortInput: $sortInput"
  else
    logWarn " Could not clean sort input."
    logError "Error 12 [File Error] $sortInputRaw"
    error=12
  fi
}

function getDbInfo {
  logInfo "Getting Database Info..."
  dbQuery="SELECT id FROM $dbList WHERE sortInput=\"$sortInput\""
  doDbQuery
  id="$dbResult"
  if [[ "$id" != "" ]]; then
    isInDB=1
    logInfo " ID retrieved. Continuing..."
    logInfo " id: $id"

    dbQuery="SELECT sortComplete FROM $dbList WHERE id=\"$id\""
    doDbQuery
    sortComplete="$dbResult"
    if [[ "$sortComplete" == "0" ]]; then
      logInfo " Not already sorted. Continuing..."
      logInfo " id: $id"

      for i in movieOrTV folderOrFile fileType movieName movieYear movieQuality tvStyle tvName tvSeason tvEpisode tvYear tvDate sortPotential sortComplete sortError; do
        dbQuery="SELECT $i FROM $dbList WHERE id=$id"
        doDbQuery
        declare -g $i="$dbResult"
        logInfo " $i: ${!i}"
      done

      if [[ sortError != "" ]]; then error="$sortError"; fi

    else
      logInfo " Already sorted. Passing to save time."
    fi
  else
    isInDB=0
    logInfo " Could not find information in database."
  fi
}

function getTimeSinceModify {
  logInfo "Getting time since last modification..."
  timeSinceModify=$(( $( date +%s ) - $( date -r "$sortDir/$sortInput" +%s ) ))
  if [[ $timeSinceModify -gt 0 ]]; then
    logInfo " Modification time acquired."
    logInfo " timeSinceModify: $timeSinceModify"
  else
    logWarn " Could not get modification time."
    logError "Error 12 [File Read Error] $sortInput"
    error=12
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
    error=25
  fi
}

function updateInfoError {
  logInfo "Updating Information in Database..."
  dbQuery="UPDATE $dbList SET sortError = $error WHERE id=\"$id\""
  doDbQuery
  dbQuery="SELECT sortError FROM $dbList WHERE id=\"$id\""
  doDbQuery
  if [[ "$dbResult" == "$sortError" ]]; then
    logInfo " Status updated succeessfully."
  else
    logWarn " Could not update database."
    logError "Error 25 [Database Modify Error]"
    error=25
  fi
}

function uploadInfo {
  logInfo "Uploading Information to Database..."
  if [[ $movieOrTV == 1 ]]; then
    dbQuery="INSERT INTO sortList (sortInput, movieOrTV, folderOrFile, fileType, movieName, movieYear, movieQuality, sortPotential) VALUES (\"$sortInput\", \"1\", \"$folderOrFile\", \"$fileType\", \"$movieName\", \"$movieYear\", \"$movieQuality\", \"$sortDefault\")"
    doDbQuery
  elif [[ $tvStyle == 1 ]]; then
    dbQuery="INSERT INTO sortList (sortInput, movieOrTV, folderOrFile, fileType, tvStyle, tvName, tvSeason, tvEpisode, sortPotential) VALUES (\"$sortInput\", \"$movieOrTV\", \"$folderOrFile\", \"$fileType\", \"$tvStyle\", \"$tvName\", \"$tvSeason\", \"$tvEpisode\", \"$sortDefault\")"
    doDbQuery
  elif [[ $tvStyle == 2 ]]; then
    dbQuery="INSERT INTO sortList (sortInput, movieOrTV, folderOrFile, fileType, tvStyle, tvName, tvYear, tvDate, sortPotential) VALUES (\"$sortInput\", \"$movieOrTV\", \"$folderOrFile\", \"$fileType\", \"$tvStyle\", \"$tvName\", \"$tvYear\", \"$tvDate\", \"$sortDefault\")"
    doDbQuery
  else
    dbQuery="INSERT INTO sortList (sortInput, sortPotential) VALUES (\"$sortInput\", \"$sortDefault\")"
    doDbQuery
  fi
  dbQuery="SELECT id FROM $dbList WHERE sortInput=\"$sortInput\""
  doDbQuery
  if [[ "$dbResult" != "" ]]; then
    logInfo " Information uploaded succeessfully."
  else
    logWarn " Could not insert row to database."
    logError "Error 24 [Database Write Error]"
    error=24
  fi
}


# PARSE FUNCTIONS
function findMovieOrTv {
  logInfo "Finding Movie/TV Status..."
  for sampleFile in "$tvDir"/*; do
    if [[ "$sampleFile" =~ .{${#tvDir}}.(.*)$ ]]; then tvNameTest="${BASH_REMATCH[1]}"; fi
    if [[ "$sampleFile" =~ .{${#tvDir}}.(.{1,17}) ]]; then sampleMod="${BASH_REMATCH[1]}"; fi
    sampleMod=${sampleMod//\./} && sampleMod=${sampleMod//\ /\.}
    sampleMod=${sampleMod/\'/} && sampleMod=${sampleMod/\(/} && sampleMod=${sampleMod/\)/}
    inputMod=${sortInput/\'/}
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
    logInfo " Assuming it's a movie."
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
    logWarn " Are you sure this is a thing that can be sorted?"
    logError "Error 32 [Movie Data Error] $sortInput"
    error=32
  fi
}

function findMovieQuality {
  logInfo "Finding Movie Quality..."
  if [[ $sortInput =~ "DVD[Ss][Cc][Rr]" ]] || [[ $sortInput =~ "HC.HD[Rr][Ii][Pp]" ]] || [[ $sortInput =~ "CAM" ]]; then movieQuality="CAM"
  elif [[ $sortInput =~ "720p" ]]; then movieQuality="720p"
  elif [[ $sortInput =~ "1080p" ]]; then movieQuality="1080p"
  else
    logWarn " Could not find a valid quality."
    logError "Error 33 [Movie Quality Error] $sortInput"
    error=33
    #movieQuality="UNKNOWN"
    #logWarn " Could not find a valid quality. Continuing anyways."
  fi
  logInfo " Quality matched: $movieQuality"
}

function findFileType {
  logInfo "Finding Filetype..."
  if [[ -n $( find "$sortDir/$sortInput" -name "*.rar" ) ]]; then fileType="rar";
  elif [[ -n $( find "$sortDir/$sortInput" -name "*.mkv" ) ]]; then fileType="mkv";
  elif [[ -n $( find "$sortDir/$sortInput" -name "*.mp4" ) ]]; then fileType="mp4";
  elif [[ -n $( find "$sortDir/$sortInput" -name "*.avi" ) ]]; then fileType="avi";
  else
    logWarn " Could not find a video file/archive. Are you sure the file exists?"
    logError "Error 34 [Filetype Error] $sortInput"
    error=34
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
      logError "Error 31 [TV Data Error] $sortInput"
      error=31
    fi
  fi
}


# SORT FUNCTIONS
function seeIfExistsMovie {
  logInfo "Finding Movie..."
  if [[ -n $( find "$movieDir" -name "${movieName}*" ) ]]; then
    if [[ -n $( find "$movieDir" -name "${movieName}*CAM*" ) ]] && [[ $movieQuality == "720p" || $movieQuality == "1080p" ]]; then
      logWarn " Deleting CAM version to make way for $movieQuality version."
      rm "$movieDir/$movieName"*CAM*
    elif [[ -n $( find "$movieDir" -name "${moviename}*720p*" ) ]] && [[ $movieQuality == "1080p" ]]; then
      logWarn " Deleting 720p version to make way for $movieQuality version."
      rm "$movieDir/$movieName"*720p*
    else
      logError "Error 46 [Movie Already Exists] $sortInput"
      error=46
    fi
  else
    logInfo " Movie does not already exist. Proceeding."
  fi
}

function seeIfExistsTV1 {
  logInfo "Finding Episode..."
  if [[ -n $( find "$tvDir/$tvName/Season $tvSeason" -name "*[Ee]${tvEpisode}*" 2> /dev/null ) ]]; then
    if [[ $sortInput =~ "PROPER" ]]; then
      logWarn " Deleting old version to make way for PROPER."
      rm "$tvDir/$tvName/Season $tvSeason/"*E$tvEpisode*
    else
      logError "Error 45 [Episode Already Exists] $sortInput"
      error=45
    fi
  else
    logInfo " Episode does not already exist. Proceeding."
  fi
}

function seeIfExistsTV2 {
  logInfo "Finding Episode..."
  if [[ -n $( find "$tvDir/$tvName/Season $tvYear" -name "*${tvDate}*" 2> /dev/null ) ]]; then
    logError "Error 45 [Episode Already Exists] $sortInput"
    error=45
  else
    logInfo " Episode does not already exist. Proceeding."
  fi
}

function sortMovie {
  logInfo "Sorting Movie..."
  movieFullname="$movieName [$movieYear] [$movieQuality]"
  if [[ $fileType == mkv ]] || [[ $fileType == mp4 ]] || [[ $fileType == avi ]]; then
    if [[ $folderOrFile == 1 ]]; then
      movieSource="$sortDir/$sortInput/$( ls -S $sortDir/$sortInput | grep $fileType | head -1 )"
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

function verifyMovie {
  logInfo "Finding Movie..."
  if [[ -n $( find "$movieDir" -name "${movieName}*" ) ]]; then
    logInfo " Movie transferred successfully"
    logSuccess "New Movie: $movieFullname"
  else
    logWarn " Movie was not found."
    logError "Error 48 [Movie Transfer Error] $sortInput"
    error=48
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
    error=47
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
    error=47
  fi
}
