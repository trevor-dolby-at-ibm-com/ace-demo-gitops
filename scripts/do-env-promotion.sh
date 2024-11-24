#!/bin/bash


export sourceEnv=$1
export destEnv=$2
export applicationName=$3
export ghToken=$4

if [ "$sourceEnv" == "" ]; then
   echo "Need valid source env"
   exit 1
fi 
if [ "$destEnv" == "" ]; then
   echo "Need valid dest env"
   exit 1
fi 
if [ "$applicationName" == "" ]; then
   echo "Need valid applicationName"
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
echo $ghToken | gh auth login --with-token
gh auth setup-git
mkdir gitops_cd
cd gitops_cd
git clone --depth 20 https://github.com/${GITHUB_REPOSITORY}
cd $REPO_NAME
git checkout ${DEST_BRANCH_NAME} 2>/dev/null || git checkout -b ${DEST_BRANCH_NAME}
cd ../..

echo "#  #######################################################################"
echo "#   Calling scan-commits-for-image-changes.sh"
echo "#     ${sourceEnv} ${destEnv} ${applicationName} ${GITHUB_EVENT_PATH} gitops_cd/$REPO_NAME"
echo "#  #######################################################################"
scripts/scan-commits-for-image-changes.sh ${sourceEnv} ${destEnv} ${applicationName} ${GITHUB_EVENT_PATH} gitops_cd/$REPO_NAME
echo "#  #######################################################################"
echo "#   Calling push-changes-to-new-branch.sh"
echo "#     ${destEnv} gitops_cd/$REPO_NAME"
echo "#  #######################################################################"
scripts/push-changes-to-new-branch.sh ${destEnv} gitops_cd/$REPO_NAME
