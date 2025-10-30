#!/bin/bash

set -ex

git clone --depth=1 git@github.com:$GITHUB_ORG/$GITHUB_REPO.git
if [ "$CLOUD_PROVIDER" != "YARN" ]; then
  FILE=$(ls -1tr *_manifest.json | tail -1 | sed "s/_manifest//")
else
  FILE=$(ls -1tr ${IMAGE_NAME}*.json)
fi
cp $FILE $GITHUB_REPO
mkdir -p "${GITHUB_REPO}/manifest"
UUID=$(cat $FILE | jq -r .uuid)
if [ "$CLOUD_PROVIDER" != "YARN" ]; then
  cp installed-delta-packages.csv "${GITHUB_REPO}/manifest/${UUID}-manifest.csv"
  cp installed-full-packages.csv "${GITHUB_REPO}/manifest/${UUID}-full-manifest.csv"
fi

pushd $GITHUB_REPO
git add -A
git commit -am "Upload new metadata files for ${UUID}"

git pull --rebase origin master

git push
popd