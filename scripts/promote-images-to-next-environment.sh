#!/bin/bash


export sourceEnv=$1
export destEnv=$2
export gitCommit=$3
export destDirectory=$4

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
echo "#       sourceEnv: ${sourceEnv}"
echo "#       destEnv: ${destEnv}"
echo "#      #######################################################################"
git show --name-only "${gitCommit}" 
export YAMLFILES=$(git show --name-only "${gitCommit}" | grep "/${sourceEnv}")

for yamlFile in $YAMLFILES; do
  # Make sure there's at least one match
  [ -e "${yamlFile}" ] || continue

  export imageName=$(yq '.images[0].newName' ${yamlFile})
  if [ "$imageName" == "null" ]; then
    echo "$yamlFile does not contain an image reference"
  else
    export imageTag=$(yq '.images[0].newTag' ${yamlFile})
    export applicationName=$(echo $yamlFile | awk '{split($0,a,"/"); print a[1]}')
    export parentDirPath=$(echo $(dirname $yamlFile) | sed "s|/${sourceEnv}|\n|g" | head -n 1)
    export modifiedFilePath=$(echo $yamlFile | sed "s|/${sourceEnv}/|\n|g" | tail -n 1)
    export destEnvYamlDir="$(dirname ${destDirectory}/${parentDirPath}/${destEnv}/${modifiedFilePath})"
    export destEnvYamlFile="${destDirectory}/${parentDirPath}/${destEnv}/${modifiedFilePath}"
    echo "#      #######################################################################"
    echo "#       Changing image reference for ${applicationName}"
    echo "#       to ${imageName}:${imageTag}"
    echo "#       in $destEnvYamlFile"
    echo "#      #######################################################################"
    mkdir -p ${destEnvYamlDir}
    cp ${yamlFile} ${destEnvYamlFile}
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

