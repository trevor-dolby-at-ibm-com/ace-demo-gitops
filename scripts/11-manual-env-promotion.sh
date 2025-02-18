#!/bin/bash

export applicationName=$1
export sourceEnv=$2
export destEnv=$3
export ghToken=$4

if [ "$applicationName" == "" ]; then
   echo "Need valid application name"
   exit 1
fi 
if [ "$sourceEnv" == "" ]; then
   echo "Need valid source env"
   exit 1
fi 
if [ "$destEnv" == "" ]; then
   echo "Need valid dest env"
   exit 1
fi 
if [ "$ghToken" == "" ]; then
   echo "Need valid ghToken"
   exit 1
fi 

git config --global user.email "trevor.dolby@ibm.com"
git config --global user.name "Trevor Dolby (automation)"
git config --global --add --bool push.autoSetupRemote true

export BRANCH_NAME=${GITHUB_HEAD_REF}
if [ "$BRANCH_NAME" == "" ]; then
  export BRANCH_NAME="$GITHUB_REF_NAME"
fi
export DEST_BRANCH_NAME="autoPr/${applicationName}/${destEnv}"
export REPO_NAME=$(basename `echo $GITHUB_REPOSITORY`)
echo "#  #######################################################################"
echo "#   Cloning a new copy of the repo using the correct credentials"
echo "#   Repo    ${GITHUB_REPOSITORY}"
echo "#   Branch  ${DEST_BRANCH_NAME}"
echo "#  #######################################################################"
mkdir -p gitops_cd
echo $ghToken | gh auth login --with-token
gh auth setup-git
cd gitops_cd
git clone https://github.com/${GITHUB_REPOSITORY}
cd $REPO_NAME
git checkout ${DEST_BRANCH_NAME} 2>/dev/null || git checkout -b ${DEST_BRANCH_NAME}
git pull
# Reset working directory to original
cd ../..
echo "#  #######################################################################"
echo "#  Calling ../../scripts/13-promote-image-to-next-environment.sh"
echo "#    ${applicationName} ${sourceEnv} ${destEnv} gitops_cd/$REPO_NAME"
echo "#  #######################################################################"
scripts/13-promote-image-to-next-environment.sh ${applicationName} ${sourceEnv} ${destEnv} gitops_cd/$REPO_NAME


echo "#  #######################################################################"
echo "#   Calling 04-push-changes-to-new-branch.sh"
echo "#     ${destEnv} gitops_cd/$REPO_NAME"
echo "#  #######################################################################"
scripts/04-push-changes-to-new-branch.sh ${destEnv} gitops_cd/$REPO_NAME
