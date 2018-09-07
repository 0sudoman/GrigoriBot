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

# set defaults
movieOrTV=-1
folderOrFile=-1
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

# MAIN FUNCTION
getInput
findFileType
findFolderOrFile
findMovieOrTv

if [[ $movieOrTV == 1 ]]; then
  findMovieData
  findMovieQuality
elif [[ $movieOrTV == 2 ]]; then
  findTvData
fi

if [[ $movieOrTV == 1 ]]; then
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
