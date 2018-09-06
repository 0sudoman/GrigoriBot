#!/bin/bash
# sort.sh
# sorts out TV shows and shit

# STARTUP INFO
botDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$botDir/config.sh"
scriptName="sort.sh"
logInfo "Started..."

sortArgs=("$@")

# set defaults
isMovie=-1
isTV=-1
isFolder=-1
isFile=-1
fileType=-1

movieName=-1
movieYear=-1
movieQuality=-1

tvName=-1
tvStyle=-1
tvSeason=-1
tvEpiosde=-1
tvYear=-1
tvDate=-1

function getInput {
  logInfo "Getting Input..."
  sortInput="${sortArgs[0]}"
  logInfo " Input Acquired: $sortInput"
}

function findMovieOrTv {
  logInfo "Finding Movie/TV Status..."
  for sampleFile in $tvDir/*; do
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
    isMovie=0
    isTV=1
    logInfo " Movie/TV Status: TV"
    logInfo " Show matched: $tvName"
  else
    isMovie=1
    isTV=0
    logInfo " No TV Show found."
    logInfo " Assuming it's a movie."
  fi
}

function findMovieData {
  logInfo "Finding Movie Information..."
  if [[ $sortInput =~ (.*).(19|20)([0-9]{2}) ]]; then
    movieName="${BASH_REMATCH[1]}"
    movieYear="${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
    for i in $( seq 10 ); do MOVIENAME=${MOVIENAME/\./\ }; done
    logInfo " Movie/TV Status: Movie"
    logInfo " Movie matched: $movieName [$movieYear]"
  else
    logWarn " Could not find a year. It's probably not a movie."
    logWarn " Are you sure this is a thing that can be sorted?"
    logError "Error 42 [Movie Data Error] $sortInput"
    exit
  fi
}

function findMovieQuality {
  logInfo "Finding Movie Quality..."
  if [[ $sortInput =~ "DVD[Ss][Cc][Rr]" ]] || [[ $sortInput =~ "HC.HD[Rr][Ii][Pp]" ]] || [[ $sortInput =~ "CAM" ]]; then movieQuality="CAM"
  elif [[ $sortInput =~ "720p" ]]; then movieQuality="720p"
  elif [[ $sortInput =~ "1080p" ]]; then movieQuality="1080p"
  else
    #logWarn " Could not find a valid quality."
    #logError "Error 43 [Movie Quality Error] $sortInput"
    #exit #seems a little harsh
    movieQuality="UNKNOWN"
    logWarn " Could not find a valid quality. Continuing anyways."
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
    logError "Error 44 [Filetype Error] $sortInput"
    exit
  fi
  if [[ "$fileType" != -1 ]]; then
    logInfo " Filetype matched: $fileType"
  fi
}

function findFolderOrFile {
  logInfo "Finding Folder/File Status..."
  if [[ $sortInput =~ $fileType ]]; then
    isFolder=0
    isFile=1
    logInfo " Folder/File Status: File"
  else
    isFolder=1
    isFile=0
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
      logError "Error 41 [TV Data Error] $sortInput"
      exit
    fi
  fi
}

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
      exit
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
      rm "$tvDir/$tvName/Season $tvSeason/*E$tvSeason*"
    fi
    logError "Error 45 [Episode Already Exists] $sortInput"
    exit
  else
    logInfo " Episode does not already exist. Proceeding."
  fi
}

function seeIfExistsTV2 {
  logInfo "Finding Episode..."
  if [[ -n $( find "$tvDir/$tvName/Season $tvYear" -name "*${tvDate}*" 2> /dev/null ) ]]; then
    logError "Error 45 [Episode Already Exists] $sortInput"
    exit
  else
    logInfo " Episode does not already exist. Proceeding."
  fi
}

function sortMovie {
  logInfo "Sorting Movie..."
  movieFullname="$movieName [$movieYear] [$movieQuality]"
  if [[ $fileType == mkv ]] || [[ $fileType == mp4 ]] || [[ $fileType == avi ]]; then
    if [[ $isFolder == 1 ]]; then
      movieSource="$sortDir/$sortInput/$( ls -S $sortDir/$sortInput | grep $fileType | head -1 )"
      movieTarget="$movieDir/$movieFullname.$fileType"
      logInfo " Copying '$movieSource' to '$movieTarget'"
      cp "$movieSource" "$movieTarget"
    elif [[ $isFile == 1 ]]; then
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
    if [[ $isFolder == 1 ]]; then
      tvSource="$sortDir/$sortInput/$( ls -S $sortDir/$sortInput | grep $fileType | head -1 )"
      tvTarget="$tvDir/$tvName/Season $tvSeason"
      logInfo " Copying '$tvSource' to '$tvTarget'"
      if [[ $tvEpisode == 01 ]]; then mkdir "$tvTarget" > /dev/null; fi
      cp "$tvSource" "$tvTarget"
    elif [[ $isFile == 1 ]]; then
      tvSource="$sortDir/$sortInput"
      tvTarget="$tvDir/$tvName/Season $tvSeason"
      logInfo " Copying '$tvSource' to '$tvTarget'"
      if [[ $tvEpisode == 01 ]]; then mkdir "$tvTarget" > /dev/null; fi
      cp "$tvSource" "$tvTarget"
    fi
  elif [[ $fileType == rar ]]; then
    tvSourceRar="$sortDir/$sortInput"
    tvTarget="$tvDir/$tvName/Season $tvSeason"
    logInfo " Unraring '$tvSourceRar' archives to '$tvTarget'"
    unrar e "$tvSourceRar/*.rar" "$tvTarget" > /dev/null
  fi
  logInfo " Transfer complete."
}

function sortTV2 {
  logInfo "Sorting Episode..."
  if [[ $fileType == mkv ]] || [[ $fileType == mp4 ]] || [[ $fileType == avi ]]; then
    if [[ $isFolder == 1 ]]; then
      tvSource="$sortDir/$sortInput/$( ls -S $sortDir/$sortInput | grep $fileType | head -1 )"
      tvTarget="$tvDir/$tvName/Season $tvYear"
      logInfo " Copying '$tvSource' to '$tvTarget'"
      cp "$tvSource" "$tvTarget"
    elif [[ $isFile == 1 ]]; then
      tvSource="$sortDir/$sortInput"
      tvTarget="$tvDir/$tvName/Season $tvYear"
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
    exit
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
    exit
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
    exit
  fi
}


# MAIN FUNCTION
getInput
findFileType
findFolderOrFile
findMovieOrTv

if [[ $isTV == 0 ]]; then
  findMovieData
  findMovieQuality
elif [[ $isTV == 1 ]]; then
  findTvData
fi

if [[ $isMovie == 1 ]]; then
  seeIfExistsMovie
  sortMovie
  verifyMovie
elif [[ $tvStyle == 1 ]]; then
  seeIfExistsTV1
  sortTV1
  verifyTV1
else
  seeIfExistsTV2
  sortTV2
  verifyTV2
fi

logInfo "Finished."

exit
