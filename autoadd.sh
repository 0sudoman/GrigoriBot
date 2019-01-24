#!/bin/bash
# autoadd.sh
# adds new entries to database
# call this script to add files that should not be sorted
# DOES NOT SORT

# STARTUP INFO
botDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$botDir/config.sh"
source "$botDir/functions.sh"
scriptName="autoadd.sh"

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
sortDefault=0

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

    logInfo " Skipping [AutoAdd Only] $sortInput"

  fi

done

logInfo "Finished."
autosortExit
