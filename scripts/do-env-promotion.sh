#!/bin/bash


export sourceEnv=$1
export destEnv=$2
export ghToken=$3

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

echo "#  #######################################################################"
echo "#   Calling scan-commits-for-image-changes.sh"
echo "#     ${sourceEnv} ${destEnv} ${GITHUB_EVENT_PATH} gitops_cd/changed-files"
echo "#  #######################################################################"
mkdir -p gitops_cd/changed-files
scripts/scan-commits-for-image-changes.sh ${sourceEnv} ${destEnv} ${GITHUB_EVENT_PATH} gitops_cd/changed-files

# Pick up the first application name as the branch and PR name
export applicationName=$(echo commits-* | grep commits-for- | head -n 1 | sed 's/commits-for-//g')
if [ "$applicationName" == "" ]; then
   echo "No changed applications found"
   exit 0
fi 


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
cd gitops_cd
git clone https://github.com/${GITHUB_REPOSITORY}
cd $REPO_NAME
git checkout ${DEST_BRANCH_NAME} 2>/dev/null || git checkout -b ${DEST_BRANCH_NAME}
git pull
# Avoid changing the directory permissions by copying only the files
( cd ../../gitops_cd/changed-files && ( find * -type f -print | xargs tar -cf - ) ) | tar -xvf -
cd ../..

echo "#  #######################################################################"
echo "#   Calling push-changes-to-new-branch.sh"
echo "#     ${destEnv} gitops_cd/$REPO_NAME"
echo "#  #######################################################################"
scripts/push-changes-to-new-branch.sh ${destEnv} gitops_cd/$REPO_NAME
