#!/bin/bash


export destEnv=$1

if [ "$destEnv" == "" ]; then
   echo "Need valid dest env"
   exit 1
fi 

export DATE=$(date '+%Y%m%d%H%M%S')
export TAG="$DATE"
export MSG="Generator commit $TAG"
export BRANCH="autoPr/tea-ace-demo/$destEnv"
git add . 
git status
git commit -s -m "$MSG"
# Check to see if anything changed
if [[ $(git status -s | wc -l) -eq 0 ]]; then
  echo "########################################################################"
  echo "# Nothing new generated - not creating a new git commit"
  echo "########################################################################"
else
  echo "########################################################################"
  echo "# Generated files changed - creating and pushing git commit:"
  echo "# \"$MSG\""
  echo "########################################################################"
  git checkout -b $BRANCH
  git add . 
  git status
  git commit -s -m "$MSG"
  git push origin $BRANCH
fi
