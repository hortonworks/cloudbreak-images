#!/bin/bash

set -x

echo '{}' | jq --arg sb "$(salt-bootstrap --version | awk '{print $2}')" '. + {"salt-bootstrap": $sb}' > /tmp/package-versions.json
cat /tmp/package-versions.json | jq --arg sv "$(salt-call --local grains.get saltversion --out json | jq -r .local)" '. + {"salt": $sv}' > /tmp/package-versions.json

for package in "$@"
do
	if [ "$package" != "None" ]; then
		cat /tmp/package-versions.json | jq --arg p "$package" --arg v "$(salt-call --local pkg.version $package --out json | jq -r .local)" '. + {($p): $v}' > /tmp/package-versions.json
	fi
done

chmod 744 /tmp/package-versions.json

exit 0
