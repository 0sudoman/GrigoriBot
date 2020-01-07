#!/bin/bash
# forcesort.sh
# sorts out files, ignoring certain errors

# STARTUP INFO
botDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$botDir/config.sh"
source "$botDir/functions.sh"
scriptName="forcesort.sh"
logInfo "Started..."

sortArgs=("$@")

function getInput {
  logInfo "Getting Input..."
  sortInput="${sortArgs[0]}"
  logInfo " Input Acquired: $sortInput"
}

# MAIN FUNCTION
getInput

resetVariables
findFileType
findFolderOrFile
findMovieOrTV

if [[ $movieOrTV == 1 ]]; then
  findMovieData
  findMovieQuality

  if [[ $movieQuality == "UNKNOWN" ]]; then
    logInfo " Error ignored."
    movieOrTV=1
    movieQuality="CAM"
    sortError=-1
    logInfo " Quality Overridden to CAM."
  fi

elif [[ $movieOrTV == 2 ]]; then
  findTvData
fi

if [[ $sortError == -1 ]]; then
  if [[ $movieOrTV == 1 ]]; then
    seeIfExistsMovie
    if [[ $sortError != -1 ]]; then
      logInfo " Error ignored."
    fi
    sortMovie
    verifyMovie

  elif [[ $tvStyle == 1 ]]; then
    seeIfExistsTV1
    if [[ $sortError != -1 ]]; then
      logInfo " Error ignored."
    fi
    sortTV1
    verifyTV1

  elif [[ $tvStyle == 2 ]]; then
    seeIfExistsTV2
    if [[ $sortError != -1 ]]; then
      logInfo " Error ignored."
    fi
    sortTV2
    verifyTV2

  fi
fi

logInfo "Finished."

exit
