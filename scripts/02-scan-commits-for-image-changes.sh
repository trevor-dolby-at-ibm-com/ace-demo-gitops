#!/bin/bash


export sourceEnv=$1
export destEnv=$2
export githubPushEventJson=$3
export destDirectory=$4


if [ "$githubPushEventJson" == "" ]; then
   echo "Need valid githubPushEventJson"
   exit 1
fi 

echo "#    #######################################################################"
echo "#     Looking for commits to check for image tag updates from ${sourceEnv} to ${destEnv} "
echo "#    #######################################################################"
export COMMITS=$(jq '.commits[].id' ${githubPushEventJson} | tr -d '"')

if [ "$COMMITS" == "" ]; then
   echo "No commits found in file ${githubPushEventJson}; contents are"
   cat ${githubPushEventJson}
else
  for commit in $COMMITS; do
    echo "#    #######################################################################"
    echo "#     Checking commit ${commit} for changes to image tags"
    echo "#    #######################################################################"
    scripts/03-promote-images-to-next-environment.sh ${sourceEnv} ${destEnv} ${commit} ${destDirectory}
  done
fi

