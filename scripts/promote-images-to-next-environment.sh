#!/bin/bash


export sourceEnv=$1
export destEnv=$2
export gitCommit=$3



echo "########################################################################"
echo "# Scanning for changes in ${sourceEnv} YAML to propagate to ${destEnv}"
echo "########################################################################"
export YAMLFILES=$(git show --name-only "${gitCommit}" | grep "/${sourceEnv}")

for yamlFile in $YAMLFILES; do
  # Make sure there's at least one match
  [ -e "$yamlFile" ] || continue

  export imageName=$(yq '.images[0].newName' $yamlFile)
  if [ "$imageName" == "null" ]; then
    echo "$yamlFile does not contain an image reference"
  else
    export imageTag=$(yq '.images[0].newTag' $yamlFile)
    export parentDirPath=$(echo $(dirname $yamlFile) | sed "s|/${sourceEnv}|\n|g" | head -n 1)
    export modifiedFilePath=$(echo $yamlFile | sed "s|/${sourceEnv}/|\n|g" | tail -n 1)
    export destEnvYamlFile="${parentDirPath}/${destEnv}/${modifiedFilePath}"
    echo "########################################################################"
    echo "# Changing image reference to ${imageName}:${imageTag} in $destEnvYamlFile"
    echo "########################################################################"
    echo "Previous image in ${destEnvYamlFile}:"
    yq '.images[0]' $destEnvYamlFile
    set -e
    set -x
    yq -i '.images[0].newName = strenv(imageName)' $destEnvYamlFile
    yq -i '.images[0].newTag = strenv(imageTag)' $destEnvYamlFile
    set +x
    set +e
  fi
done

