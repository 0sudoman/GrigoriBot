#!/bin/bash
# autosort.sh
# does shit automagicially

# STARTUP INFO
botDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$botDir/config.sh"
source "$botDir/functions.sh"
scriptName="autosort.sh"

# MAIN FUNCTION
logInfo "Started..."
autosortStart

resetVariables

pingServer
if [[ $sortError != -1 ]]; then
  logWarn " Exiting [Server Connect Error]"
  autosortExit
fi

getSettings
if [[ $sortError != -1 ]]; then
  logWarn " Exiting [Server Connect Error]"
  autosortExit
fi

logInfo "Startup complete. Beginning iterations..."

for sortInputRaw in "$sortDir"/*; do

  resetVariables

  fixSortInput
  if [[ $sortError != -1 ]]; then
    logWarn " Skipping [Sort Input Error] $sortInputRaw"
    continue
  fi

  logInfo "Handling file: $sortInput"

  if [[ $sortInput =~ "’" ]]; then
    logWarn " Skipping [Illegal Character] $sortInput"
    continue
  fi

  getDbInfoID

  if [[ $isInDB == 0 ]]; then
    logInfo " Gathering data..."

    sortPotential=$sortDefault
    logInfo " sortPotential: $sortPotential (from default)"

    findFileType
    findFolderOrFile
    if [[ $sortError != -1 ]]; then
      sortPotential=0
      logInfo "Changing sortPotential to 0..."
      logInfo " sortPotential: $sortPotential"
      uploadDataOther
      logWarn " $sortInput complete. Moving on."
      continue
    fi

    findMovieOrTV
    if [[ $movieOrTV != 2 ]]; then

      findMovieData
      if [[ $sortError != -1 ]]; then
        sortPotential=0
        logInfo "Changing sortPotential to 0..."
        logInfo " sortPotential: $sortPotential"
        uploadDataOther
        logInfo " $sortInput complete. Moving on."
        continue
      fi

      findMovieQuality
      if [[ $sortError != -1 ]]; then
        sortPotential=0
        logInfo "Changing sortPotential to 0..."
        logInfo " sortPotential: $sortPotential"
        uploadDataOther
        logInfo " $sortInput complete. Moving on."
        continue
      fi

     if [[ $movieQuality == "2160p" ]]; then
        logWarn "Too high quality to sort automatically."
        sortPotential=0
        logInfo "Changing sortPotential to 0..."
        logInfo " sortPotential: $sortPotential"
      fi

      uploadDataMovie

    else

      findTvData
      if [[ $tvStyle == 1 ]]; then
        uploadDataTV1
      else
        uploadDataTV2
      fi

    fi

    getDbInfoID

    if [[ $sortPotential == 0 ]]; then
      logInfo " Skipping [Disabled] $sortInput"
      continue
    fi

  else

    getDbInfoPotential
    if [[ $sortPotential == 0 ]]; then
      logInfo " Skipping [Disabled] $sortInput"
      continue
    fi

    getDbInfoComplete
    if [[ $sortComplete == 1 ]]; then
      logInfo " Skipping [Complete] $sortInput"
      continue
    fi

    getDbInfoError
    if [[ $sortError != -1 ]]; then
      logInfo " Skipping [Error] $sortInput"
      continue
    fi

    getDbInfo

  fi

  if [[ $movieOrTV == 3 ]]; then
    logInfo " Skipping [Unsortable] $sortInput"
    continue
  fi

  getTimeSinceModify
  if [[ $timeSinceModify -lt $sortWaitTime ]]; then
    logInfo " Skipping [Too Soon] $sortInput"
    continue
  fi

  logInfo "Sorting..."

  if [[ $movieOrTV == 1 ]]; then

    if [[ $movieQuality == "UNKNOWN" ]]; then
      logInfo " Skipping [Low Quality] $sortInput"
      continue
    fi

    seeIfExistsMovie
    if [[ $sortError != -1 ]]; then
      logWarn " $sortInput complete [Already Exists]. Moving on."
      continue
    fi

    sortMovie
    verifyMovie
    if [[ $sortError != -1 ]]; then
      updateInfoFailure
    else
      updateInfoSuccess
    fi

  elif [[ $tvStyle == 1 ]]; then

    seeIfExistsTV1
    if [[ $sortError != -1 ]]; then
      logWarn " $sortInput complete [Already Exists]. Moving on."
      continue
    fi

    sortTV1
    verifyTV1
    if [[ $sortError != -1 ]]; then
      updateInfoFailure
    else
      updateInfoSuccess
    fi

  elif [[ $tvStyle == 2 ]]; then

    seeIfExistsTV2
    if [[ $sortError != -1 ]]; then
      logWarn " $sortInput complete [Already Exists]. Moving on."
      continue
    fi

    sortTV2
    verifyTV2
    if [[ $sortError != -1 ]]; then
      updateInfoFailure
    else
      updateInfoSuccess
    fi

  fi

done

logInfo "Finished."
autosortExit
