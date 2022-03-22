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

JUMPGATE_AGENT_VERSION_INFO=$(jumpgate-agent --version)
JUMPGATE_AGENT_VERSION_REGEX="jumpgate-agent version:\s([0-9]+\.[0-9]+\.[0-9]+\-b[0-9]+).*"
if [[ $JUMPGATE_AGENT_VERSION_INFO =~ $JUMPGATE_AGENT_VERSION_REGEX ]]; then
	cat /tmp/package-versions.json | jq --arg inverting_proxy_agent_version ${BASH_REMATCH[1]} '. + {"inverting-proxy-agent": $inverting_proxy_agent_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
else
	echo "It is not possible to retrieve the version of Jumpgate Agent from its --version param."
	exit 1
fi

JUMPGATE_AGENT_GBN_REGEX=".*\/([0-9]+)\/.*"
if [[ $JUMPGATE_AGENT_RPM_URL =~ $JUMPGATE_AGENT_GBN_REGEX ]]; then
	cat /tmp/package-versions.json | jq --arg inverting_proxy_agent_gbn ${BASH_REMATCH[1]} '. + {"inverting-proxy-agent_gbn": $inverting_proxy_agent_gbn}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
else
	echo "It is not possible to retrieve the gbn of Jumpgate Agent from the specified url."
	exit 1
fi

set_version_for_rpm_pkg "cdp-telemetry"
set_version_for_rpm_pkg "cdp-logging-agent"
set_version_for_rpm_pkg "cdp-vmagent"
set_version_for_rpm_pkg "cdp-request-signer"

if [[ -f "/opt/node_exporter/node_exporter" ]]; then
    node_exporter_version=$(/opt/node_exporter/node_exporter --version 2>&1 | grep -Po "version (\d+\.)+\d+" | cut -d ' ' -f2)
	cat /tmp/package-versions.json | jq --arg ne_version $node_exporter_version -r '. + {"node-exporter": $ne_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
fi
if [[ -f "/opt/blackbox_exporter/blackbox_exporter" ]]; then
	blackbox_exporter_version=$(/opt/blackbox_exporter/blackbox_exporter --version 2>&1 | grep -Po "version (\d+\.)+\d+" | cut -d ' ' -f2)
	cat /tmp/package-versions.json | jq --arg be_version $blackbox_exporter_version -r '. + {"blackbox-exporter": $be_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
fi

for package in "$@"
do
	if [ "$package" != "None" ]; then
		cat /tmp/package-versions.json | jq --arg p "$package" --arg v "$($SALT_PATH/bin/salt-call --local pkg.version $package --out json | jq -r .local)" '. + {($p): $v}' > /tmp/package-versions.json
	fi
done

if [[ "$CUSTOM_IMAGE_TYPE" == "freeipa" ]]; then
	FREEIPA_REGEX=".*\/[_a-z\-]*\-(.*)\.x86_64\.rpm"
	if [[ $FREEIPA_PLUGIN_RPM_URL =~ $FREEIPA_REGEX ]]; then
		cat /tmp/package-versions.json | jq --arg freeipa_plugin_version ${BASH_REMATCH[1]} '. + {"freeipa-plugin": $freeipa_plugin_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
	else
		echo "It is not possible to retrieve the version of FreeIPA Plugin from the specified url."
		exit 1
	fi
	if [[ $FREEIPA_HEALTH_AGENT_RPM_URL =~ $FREEIPA_REGEX ]]; then
		cat /tmp/package-versions.json | jq --arg freeipa_health_agent_version ${BASH_REMATCH[1]} '. + {"freeipa-health-agent": $freeipa_health_agent_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
	else
		echo "It is not possible to retrieve the version of FreeIPA Health Agent from the specified url."
		exit 1
	fi
elif [[ "$CUSTOM_IMAGE_TYPE" == "hortonworks" ]]; then
	METERING_REGEX=".*\/[_a-z\-]*\-(.*)\-.*\.x86_64\.rpm"
	if [[ $METERING_AGENT_RPM_URL =~ $METERING_REGEX ]]; then
		cat /tmp/package-versions.json | jq --arg metering_agent_version ${BASH_REMATCH[1]} '. + {"metering_agent": $metering_agent_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
	else
		echo "It is not possible to retrieve the version of Metering Agent from the specified url."
		exit 1
	fi
fi

chmod 744 /tmp/package-versions.json

exit 0
