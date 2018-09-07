#!/bin/bash
# autosort.sh
# does shit automagicially

# STARTUP INFO
botDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$botDir/config.sh"
source "$botDir/functions.sh"
scriptName="autosort.sh"
logInfo "Started..."

# MAIN FUNCTION
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
        sortMovie
        verifyMovie
        updateInfo
      elif [[ $tvStyle == 1 ]]; then
        seeIfExistsTV1
        sortTV1
        verifyTV1
        updateInfo
      elif [[ $tvStyle == 2 ]]; then
        seeIfExistsTV2
        sortTV2
        verifyTV2
        updateInfo
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
exit
