#!/bin/bash

# Replace manifest part to the result of the sparse image building
yum install -y epel-release
yum install -y jq
cat ${image_name}.json | jq --slurpfile newmanifest packer-manifest.json  '.manifest = $newmanifest' >> ${image_name}.json