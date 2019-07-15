#!/bin/bash

# Replace manifest part to the result of the sparse image building
cat ${image_name}.json | jq --slurpfile newmanifest packer-manifest.json  '.manifest = $newmanifest' >> ${image_name}.json