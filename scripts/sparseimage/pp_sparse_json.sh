#!/bin/bash

set -xe
# Replace manifest part to the result of the sparse image building
ls -al *.json
echo Image name is: $image_name 
apk update && apk add jq
newartifacts=$(cat packer-manifest.json | jq -r '.builds[0].artifact_id')
cat ${image_name}.json | jq --arg artifacts "$newartifacts"  '.manifest.builds[0].artifact_id  = $artifacts' >> temp.json
mv temp.json ${image_name}.json