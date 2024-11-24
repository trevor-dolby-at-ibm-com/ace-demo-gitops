#!/bin/bash


export destEnv=$1
export destDirectory=$2

if [ "$destEnv" == "" ]; then
   echo "Need valid dest env"
   exit 1
fi 

export DATE=$(date '+%Y%m%d%H%M%S')
export TAG="$DATE"
export MSG="Generator commit $TAG"
set -e
cd ${destDirectory}
git add . 
git status
# Check to see if anything changed
if [[ $(git status -s | wc -l) -eq 0 ]]; then
  echo "#    #######################################################################"
  echo "#     Nothing new generated - not creating a new git commit"
  echo "#    #######################################################################"
else
  echo "#    #######################################################################"
  echo "#     Generated files changed - creating and pushing git commit"
  echo "#     \"$MSG\" to branch $DEST_BRANCH_NAME"
  echo "#    #######################################################################"

  git commit -s -m "$MSG"
  git push origin $DEST_BRANCH_NAME

  echo "#    #######################################################################"
  echo "#     Creating or updating PR"
  echo "#    #######################################################################"
  gh pr list
  gh pr create --base main --head $DEST_BRANCH_NAME --title "tea-ace-demo automated promote to $destEnv" --body "Updated on $DATE"  --draft || gh pr edit --base main --title "tea-ace-demo automated promote to $destEnv" --body "Updated on $DATE"
fi
