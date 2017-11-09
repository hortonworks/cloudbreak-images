#!/bin/bash

set -e

file_name="${image_name}.json"

head=$(curl -sf -u $github_user:$github_password https://api.github.com/repos/$github_org/$github_repo/git/refs/heads/master)
commitSha=$(echo $head | jq -r .object.sha)
commitUrl=$(echo $head | jq -r .object.url)
commit=$(curl -sf -u $github_user:$github_password $commitUrl)
treeSha=$(echo $commit | jq -r .tree.sha)

blob=$(curl -sf -u $github_user:$github_password -X POST https://api.github.com/repos/$github_org/$github_repo/git/blobs -d "{\"content\":\"$(base64 $file_name)\",\"encoding\":\"base64\"}")
blobSha=$(echo $blob | jq -r .sha)

newTree=$(curl -sf -u $github_user:$github_password -X POST https://api.github.com/repos/$github_org/$github_repo/git/trees -d \
    "{\"base_tree\":\"$treeSha\",\"tree\":[{\"path\":\"$file_name\",\"mode\":\"100644\",\"type\":\"blob\",\"sha\":\"$blobSha\"}]}")
newTreeSha=$(echo $newTree | jq -r .sha)
newCommit=$(curl -sf -u $github_user:$github_password -X POST https://api.github.com/repos/$github_org/$github_repo/git/commits -d \
    "{\"message\":\"Upload $file_name\",\"parents\":[\"$commitSha\"],\"tree\":\"$newTreeSha\"}")
newCommitSha=$(echo $newCommit | jq -r .sha)
curl -s -u $github_user:$github_password -X PATCH https://api.github.com/repos/$github_org/$github_repo/git/refs/heads/master -d "{\"sha\":\"$newCommitSha\",\"force\":true}"

exit 0