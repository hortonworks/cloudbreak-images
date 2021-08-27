#!/bin/bash

set -xe
# Replace manifest part to the result of the sparse image building
ls -al *.json
echo Image name is: $image_name 
wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x jq-linux64
mv jq-linux64 /bin/jq
cat packer-manifest.json
newartifacts=$(cat packer-manifest.json | jq -r '.builds[0].artifact_id')
cat ${image_name}_$metadata_filename_postfix.json | jq --arg artifacts "$newartifacts"  '.manifest.builds[0].artifact_id  = $artifacts' >> temp.json
mv temp.json ${image_name}_$metadata_filename_postfix.json