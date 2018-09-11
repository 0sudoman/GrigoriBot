#!/bin/bash
# autosort.sh
# does shit automagicially

# STARTUP INFO
botDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$botDir/config.sh"
source "$botDir/functions.sh"
scriptName="autosort.sh"

# MAIN FUNCTION
while true; do
logInfo "Started..."

pingServer
getSettings
for sortInputRaw in "$sortDir"/*; do
  resetVariables
  fixSortInput
  getDbInfo
  if [[ $isInDB == 1 ]]; then
    getTimeSinceModify
    if [[ $timeSinceModify -gt $sortWaitTime && $sortPotential == 1 && $sortComplete == 0 ]]; then
      logInfo "Sorting $sortInput..."
      if [[ $movieOrTV == 1 ]]; then
        seeIfExistsMovie
        if [[ $error == -1 ]]; then sortMovie; fi
        if [[ $error == -1 ]]; then verifyMovie; fi
        if [[ $error == -1 ]]; then updateInfo; fi
      elif [[ $tvStyle == 1 ]]; then
        seeIfExistsTV1
        if [[ $error == -1 ]]; then sortTV1; fi
        if [[ $error == -1 ]]; then verifyTV1; fi
        if [[ $error == -1 ]]; then updateInfo; fi
      elif [[ $tvStyle == 2 ]]; then
        seeIfExistsTV2
        if [[ $error == -1 ]]; then sortTV2; fi
        if [[ $error == -1 ]]; then verifyTV2; fi
        if [[ $error == -1 ]]; then updateInfo; fi
      elif [[ $movieOrTV == 3 ]]; then
        updateInfo
      fi
    elif [[ $timeSinceModify -lt $sortWaitTime ]]; then
      loWarn "Not sorting $sortInput (too soon)."
    elif [[ $sortPotential != 1 ]]; then
      logWarn "Not sorting $sortInput (disabled)."
    elif [[ $sortComplete != 0 ]]; then
      logWarn "Not sorting $sortInput (already sorted)."
    fi
  else
    findFileType
    findFolderOrFile
    findMovieOrTv
    if [[ $movieOrTV == 1 ]]; then
      findMovieData
      findMovieQuality
    elif [[ $movieOrTV == 2 ]]; then
      findTvData
    fi
    uploadInfo
    logWarn "Uploaded $sortInput."
  fi
done

logInfo "Finished."
logInfo "Sleeping for 15 minutes..."
sleep 900
done
