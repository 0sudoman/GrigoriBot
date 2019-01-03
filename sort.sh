#!/bin/bash
# sort.sh
# sorts out TV shows and shit

# STARTUP INFO
botDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$botDir/config.sh"
source "$botDir/functions.sh"
scriptName="sort.sh"
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
      exit
    fi
    sortMovie
    verifyMovie

  elif [[ $tvStyle == 1 ]]; then
    seeIfExistsTV1
    if [[ $sortError != -1 ]]; then
      exit
    fi
    sortTV1
    verifyTV1

  elif [[ $tvStyle == 2 ]]; then
    seeIfExistsTV2
    if [[ $sortError != -1 ]]; then
      exit
    fi
    sortTV2
    verifyTV2

  fi
fi

logInfo "Finished."

exit
