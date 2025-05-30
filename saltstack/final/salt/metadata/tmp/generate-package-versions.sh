#!/bin/bash

set -x

function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

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

set_version() {
  package_name=$1
  package_version=$2
  cat /tmp/package-versions.json | jq --arg package_name ${package_name} --arg package_version ${package_version} \
    '. + {($package_name): $package_version}' > /tmp/package-versions.json.tmp \
    && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
}

echo '{}' | jq --arg sb "$(salt-bootstrap --version | awk '{print $2}')" '. + {"salt-bootstrap": $sb}' > /tmp/package-versions.json
cat /tmp/package-versions.json | jq --arg sv "$($SALT_PATH/bin/salt-call --local grains.get saltversion --out json | jq -r .local)" '. + {"salt": $sv}' > /tmp/package-versions.json

cat /tmp/package-versions.json | jq --arg git_rev ${GIT_REV} '. + {"cloudbreak_images": $git_rev}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
if [[ -n $JUMPGATE_AGENT_RPM_URL ]]; then
	JUMPGATE_AGENT_VERSION_INFO=$(jumpgate-agent --version)
	JUMPGATE_AGENT_VERSION_REGEX="jumpgate-agent version:\s([0-9]+\.[0-9]+\.[0-9]+\-b[0-9]+).*"
	if [[ $JUMPGATE_AGENT_VERSION_INFO =~ $JUMPGATE_AGENT_VERSION_REGEX ]]; then
		cat /tmp/package-versions.json | jq --arg inverting_proxy_agent_version ${BASH_REMATCH[1]} '. + {"inverting-proxy-agent": $inverting_proxy_agent_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
	else
		echo "It is not possible to retrieve the version of Jumpgate Agent from its --version param."
		exit 1
	fi
	if [[ "$CLOUD_PROVIDER" == "YARN" ]]; then
			wget $JUMPGATE_AGENT_RPM_URL
			JUMPGATE_AGENT_VERSION=$(rpm -qp --queryformat '%{VERSION}' ${JUMPGATE_AGENT_RPM_URL##*/})
  			JUMPGATE_AGENT_GBN=$(curl -Ls "https://release.infra.cloudera.com/hwre-api/latestcompiledbuild?stack=JUMPGATE&release=$JUMPGATE_AGENT_VERSION" --fail | jq -r '.gbn')
	fi
	if [[ -n $JUMPGATE_AGENT_GBN ]]; then
		cat /tmp/package-versions.json | jq --arg inverting_proxy_agent_gbn ${JUMPGATE_AGENT_GBN} '. + {"inverting-proxy-agent_gbn": $inverting_proxy_agent_gbn}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
	else
		echo "JUMPGATE_AGENT_GBN environment variable is empty."
		exit 1
	fi
fi

set_version_for_rpm_pkg "cdp-telemetry"
set_version_for_rpm_pkg "cdp-logging-agent"
set_version_for_rpm_pkg "cdp-minifi-agent"
set_version_for_rpm_pkg "cdp-request-signer"

if [[ -f "/opt/node_exporter/node_exporter" ]]; then
    node_exporter_version=$(/opt/node_exporter/node_exporter --version 2>&1 | grep -Po "version (\d+\.)+\d+" | cut -d ' ' -f2)
	cat /tmp/package-versions.json | jq --arg ne_version $node_exporter_version -r '. + {"node-exporter": $ne_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
fi
if [[ -f "/opt/blackbox_exporter/blackbox_exporter" ]]; then
	blackbox_exporter_version=$(/opt/blackbox_exporter/blackbox_exporter --version 2>&1 | grep -Po "version (\d+\.)+\d+" | cut -d ' ' -f2)
	cat /tmp/package-versions.json | jq --arg be_version $blackbox_exporter_version -r '. + {"blackbox-exporter": $be_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
fi
if [[ -f "/opt/cdp-prometheus/prometheus" ]]; then
	prometheus_version=$(/opt/cdp-prometheus/prometheus --version 2>&1 | grep -Po "version (\d+\.)+\d+" | cut -d ' ' -f2)
	cat /tmp/package-versions.json | jq --arg pr_version $prometheus_version -r '. + {"cdp-prometheus": $pr_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
fi

for package in "$@"
do
	if [ "$package" != "None" ]; then
		cat /tmp/package-versions.json | jq --arg p "$package" --arg v "$($SALT_PATH/bin/salt-call --local pkg.version $package --out json | jq -r .local)" '. + {($p): $v}' > /tmp/package-versions.json
	fi
done

if [[ "$CUSTOM_IMAGE_TYPE" == "freeipa" ]]; then
  set_version_for_rpm_pkg "ipa-server"
  set_version_for_rpm_pkg "ipa-server-trust-ad"

	FREEIPA_REGEX=".*\/[_a-z\-]*\-(.*)\.(aarch64|x86_64)\.rpm"
	if [[ $FREEIPA_PLUGIN_RPM_URL =~ $FREEIPA_REGEX ]]; then
		cat /tmp/package-versions.json | jq --arg freeipa_plugin_version ${BASH_REMATCH[1]} '. + {"freeipa-plugin": $freeipa_plugin_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
	else
		echo "It is not possible to retrieve the version of FreeIPA Plugin from the specified url."
		exit 1
	fi
	if [[ $FREEIPA_HEALTH_AGENT_RPM_URL =~ $FREEIPA_REGEX ]]; then
		cat /tmp/package-versions.json | jq --arg freeipa_health_agent_version ${BASH_REMATCH[1]} '. + {"freeipa-health-agent": $freeipa_health_agent_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
	else
		echo "WARNING: It is not possible to retrieve the version of FreeIPA Health Agent from the specified url."
	fi
	if [[ $FREEIPA_LDAP_AGENT_RPM_URL =~ $FREEIPA_REGEX ]]; then
		cat /tmp/package-versions.json | jq --arg freeipa_ldap_agent_version ${BASH_REMATCH[1]} '. + {"freeipa-ldap-agent": $freeipa_ldap_agent_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
	else
		echo "WARNING: It is not possible to retrieve the version of FreeIPA LDAP Agent from the specified url."
	fi
elif [[ "$CUSTOM_IMAGE_TYPE" == "hortonworks" ]]; then
  if [[ -n $METERING_AGENT_RPM_URL ]]; then
    METERING_REGEX=".*\/[_a-z\-]*\-(.*)\-.*\.(aarch64|x86_64)\.rpm"
    if [[ $METERING_AGENT_RPM_URL =~ $METERING_REGEX ]]; then
      cat /tmp/package-versions.json | jq --arg metering_agent_version ${BASH_REMATCH[1]} '. + {"metering_agent": $metering_agent_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
    else
      echo "WARNING: It is not possible to retrieve the version of Metering Agent from the specified url."
    fi
  fi

	if [ -n "$STACK_VERSION" ] && [ $(version $STACK_VERSION) -lt $(version "7.2.15") ]; then
		echo "Skip java versions as CB should not allow to force java version before 7.2.15"
	else
		cat /tmp/package-versions.json | jq --arg default_java_version ${DEFAULT_JAVA_MAJOR_VERSION} '. + {"java": $default_java_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json

		alternatives --display java | grep priority | grep -oP '^[^ ]*java' | while read -r java_path ; do
			JAVA_VERSION_KEY=java$($java_path -version 2>&1 | grep -oP "version [^0-9]?(1\.)?\K\d+" || true)
			JAVA_VERSION=$($java_path -version 2>&1 | grep -oP 'version\s"\K[^"]+' || true)

			cat /tmp/package-versions.json | jq --arg java_version_key ${JAVA_VERSION_KEY} --arg java_version ${JAVA_VERSION} '. + {($java_version_key): $java_version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
		done
	fi

	set_version "psql" "$(psql -V | grep -oP "psql \(PostgreSQL\) \K\d+" || true)"
  alternatives --display pgsql-psql | grep priority | grep -oP '^[^ ]*psql' | while read -r psql_path ; do
    PSQL_VERSION_KEY="psql$($psql_path -V | grep -oP "psql \(PostgreSQL\) \K\d+" || true)"
    PSQL_VERSION=$($psql_path -V | grep -oP "psql \(PostgreSQL\) \K.*" || true)
    set_version "$PSQL_VERSION_KEY" "$PSQL_VERSION"
  done
fi


source /tmp/python_install.properties

if [[ -n "$PYTHON27" ]]; then
	cat /tmp/package-versions.json | jq --arg version ${PYTHON27} '. + {"python27": $version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
fi

if [[ -n "$PYTHON36" ]]; then
	cat /tmp/package-versions.json | jq --arg version ${PYTHON36} '. + {"python36": $version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
fi

if [[ -n "$PYTHON38" ]]; then
	cat /tmp/package-versions.json | jq --arg version ${PYTHON38} '. + {"python38": $version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
fi

if [[ -n "$PYTHON39" ]]; then
	cat /tmp/package-versions.json | jq --arg version ${PYTHON39} '. + {"python39": $version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
fi

if [[ -n "$PYTHON311" ]]; then
	cat /tmp/package-versions.json | jq --arg version ${PYTHON311} '. + {"python311": $version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
fi

if [[ -n "$RHEL_VERSION" ]]; then
	cat /tmp/package-versions.json | jq --arg version ${RHEL_VERSION} '. + {"os-version": $version}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
fi

if [[ "$CLOUD_PROVIDER" == "AWS"* ]]; then
	cat /tmp/package-versions.json | jq '. + {"imds": "v2"}' > /tmp/package-versions.json.tmp && mv /tmp/package-versions.json.tmp /tmp/package-versions.json
fi

chmod 644 /tmp/package-versions.json

exit 0
