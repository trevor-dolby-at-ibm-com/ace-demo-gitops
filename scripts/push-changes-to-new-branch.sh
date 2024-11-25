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

export TOPDIR=$PWD
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
  echo "Updated on $DATE" > pr-body.txt
  export COMMITFILES=$(cd ${TOPDIR} && find * -type f -maxdepth 1 -name "commits-for-*" -print)
  for commitFile in $COMMITFILES; do
    # Make sure there's at least one match
    [ -e "${TOPDIR}/${commitFile}" ] || continue

    export imageTag=$(yq '.images[0].newTag' ${yamlFile})
    export applicationName=$(echo $commitFile | sed "s|commits-for-||g")
    echo "Commits for ${applicationName}:" >> ${TOPDIR}/pr-body.txt
    cat ${TOPDIR}/${commitFile} >> ${TOPDIR}/pr-body.txt
    echo "" >> ${TOPDIR}/pr-body.txt
  done
  cat ${TOPDIR}/pr-body.txt
  git status
  git commit -s -m "$MSG"
  git push origin $DEST_BRANCH_NAME

  echo "#    #######################################################################"
  echo "#     Creating or updating PR"
  echo "#    #######################################################################"
  gh pr list
  gh pr create --base main --head $DEST_BRANCH_NAME --title "tea-ace-demo automated promote to $destEnv" --body "`cat pr-body.txt`"  --draft || gh pr edit --base main --title "tea-ace-demo automated promote to $destEnv" --body "`cat pr-body.txt`"
fi

