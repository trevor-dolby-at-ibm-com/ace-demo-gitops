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
echo "#   Calling 02-scan-commits-for-image-changes.sh"
echo "#     ${sourceEnv} ${destEnv} ${GITHUB_EVENT_PATH} gitops_cd/changed-files"
echo "#  #######################################################################"
mkdir -p gitops_cd/changed-files
scripts/02-scan-commits-for-image-changes.sh ${sourceEnv} ${destEnv} ${GITHUB_EVENT_PATH} gitops_cd/changed-files

# At this point, the 02-scan-commits-for-image-changes.sh will have created files
# of the form commits-for-APPNAME that contain the list of git commits that 
# changed the image tag; there could be more than one commit affecting any
# given application, and in thgeory we might see multiple applications changed
# by a given commit. We're going to take the first one to use in the branch
# name and PR text further down because it's an unlikely case: in general, 
# there will only be one application changed. Complex cases will probably need
# a manually-created PR rather than this automated one . . . 

# Pick up the first application name as the branch and PR name
export applicationName=$(echo commits-* | grep commits-for- | head -n 1 | sed 's/commits-for-//g')
if [ "$applicationName" == "" ]; then
  echo "#  #######################################################################"
  echo "#  No changed applications found"
  echo "#  #######################################################################"
  exit 0
fi 

# Now we have a valid application name, create the new branch and then copy in
# the changed files (created by 02-scan-commits-for-image-changes.sh) to the newly-
# cloned branch. Note that we couldn't clone the repo with the correct branch
# before calling 02-scan-commits-for-image-changes.sh because we don't know the
# application name until 02-scan-commits-for-image-changes.sh tells us . . . 
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
echo "#  #######################################################################"
echo "#  Copying in changed files"
echo "#  #######################################################################"
# Avoid changing the directory permissions by copying only the files
( cd ../../gitops_cd/changed-files && ( find * -type f -print | xargs tar -cf - ) ) | tar -xvf -
cd ../..

echo "#  #######################################################################"
echo "#   Calling 04-push-changes-to-new-branch.sh"
echo "#     ${destEnv} gitops_cd/$REPO_NAME"
echo "#  #######################################################################"
scripts/04-push-changes-to-new-branch.sh ${destEnv} gitops_cd/$REPO_NAME automated
