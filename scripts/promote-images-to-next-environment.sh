#!/bin/bash


export sourceEnv=$1
export destEnv=$2
export applicationName=$3
export gitCommit=$4
export destDirectory=$5

if [ "$sourceEnv" == "" ]; then
   echo "Need valid source env"
   exit 1
fi 
if [ "$destEnv" == "" ]; then
   echo "Need valid dest env"
   exit 1
fi 
if [ "$gitCommit" == "" ]; then
   echo "Need valid gitCommit"
   exit 1
fi 

echo "#      #######################################################################"
echo "#       Scanning for image changes in YAML"
echo "#       applicationName: $applicationName"
echo "#       sourceEnv: ${sourceEnv}"
echo "#       destEnv: ${destEnv}"
echo "#      #######################################################################"
git show --name-only "${gitCommit}" 
export YAMLFILES=$(git show --name-only "${gitCommit}" | grep "/${sourceEnv}" | grep "${applicationName}")

for yamlFile in $YAMLFILES; do
  # Make sure there's at least one match
  [ -e "${yamlFile}" ] || continue

  export imageName=$(yq '.images[0].newName' ${yamlFile})
  if [ "$imageName" == "null" ]; then
    echo "$yamlFile does not contain an image reference"
  else
    export imageTag=$(yq '.images[0].newTag' ${yamlFile})
    export parentDirPath=$(echo $(dirname $yamlFile) | sed "s|/${sourceEnv}|\n|g" | head -n 1)
    export modifiedFilePath=$(echo $yamlFile | sed "s|/${sourceEnv}/|\n|g" | tail -n 1)
    export destEnvYamlFile="${destDirectory}/${parentDirPath}/${destEnv}/${modifiedFilePath}"
    echo "#      #######################################################################"
    echo "#       Changing image reference to ${imageName}:${imageTag}"
    echo "#       in $destEnvYamlFile"
    echo "#      #######################################################################"
    echo "Previous image in ${destEnvYamlFile}:"
    yq '.images[0]' $destEnvYamlFile
    set -e
    set -x
    yq -i '.images[0].newName = strenv(imageName)' $destEnvYamlFile
    yq -i '.images[0].newTag = strenv(imageTag)' $destEnvYamlFile
    set +x
    set +e
    # Used later to populate the PR comment
    echo "${gitCommit}: ${imageName}:${imageTag}" >> commits-for-${applicationName}
  fi
done

