#!/bin/bash

set -x

set_version_for_rpm_pkg() {
	package_name=$1
	package_installed=$(rpm -q "$package_name" 2>&1 >/dev/null; echo $?)
	if [[ "$package_installed" == "0" ]]; then
		rpm_version=$(rpm -q --queryformat '%-{VERSION}' "$package_name")
		echo "{\"$package_name\": \"$rpm_version\"}" > /tmp/add_pkg_version.json.tmp
		jq -s '.[0] * .[1]' /tmp/add_pkg_version.json.tmp /tmp/package-versions.json > /tmp/package-versions.json.tmp
		rm -f /tmp/add_pkg_version.json.tmp
		mv /tmp/package-versions.json.tmp /tmp/package-versions.json
	fi
}

echo '{}' | jq --arg sb "$(salt-bootstrap --version | awk '{print $2}')" '. + {"salt-bootstrap": $sb}' > /tmp/package-versions.json
cat /tmp/package-versions.json | jq --arg sv "$($SALT_PATH/bin/salt-call --local grains.get saltversion --out json | jq -r .local)" '. + {"salt": $sv}' > /tmp/package-versions.json

cat /tmp/package-versions.json | jq --arg git_rev ${GIT_REV} '. + {"cloudbreak_images": $git_rev}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json


chmod 744 /tmp/package-versions.json

exit 0
