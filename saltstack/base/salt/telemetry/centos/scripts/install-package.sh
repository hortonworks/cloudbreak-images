#!/bin/sh
package=${1:?"usage: <package>"}
archive_base_url=${2:?"usage: <archive_url>"}
auth=${3:?"usage: <username:password>"}
s3_url=$4
#archive_telemetry_base_url="$archive_base_url/cdp-infra-tools/latest/redhat7/yum"
archive_telemetry_base_url="https://cloudera-build-us-west-1.vpc.cloudera.com/s3/build/37269492/cdp-infra-tools/0.x/redhat8/yum/"
artifacts_url="$archive_telemetry_base_url/artifacts.txt"
rpm_package=$(echo "$package" | tr '_' '-')

echo "Installing $package ..."

is_component_installed() {
  component=${1:?"usage: <component>"}
  installed=$(rpm -q "$component" 2>&1 >/dev/null; echo $?)
  echo "$installed"
}

is_rpm_package_installed=$(is_component_installed $rpm_package)
if [[ "$is_rpm_package_installed" == "0" ]]; then
  echo "Component $rpm_package has been already installed."
  exit 0
fi

status_code=$(curl -L -k -s -u $auth -o /tmp/artifacts.txt -w "%{http_code}" "$artifacts_url")
echo "Status code of fetching file 'artifacts.txt' from $archive_telemetry_base_url: $status_code"
if [[ "$status_code" == "200" ]]; then
  rpm_file_to_download=$(cat /tmp/artifacts.txt | awk "/$package/" | awk '/rpm$/' | head -1)
  rpm_url="$archive_telemetry_base_url/$rpm_file_to_download"
  echo "Installing from $rpm_url"
  curl -k -L -u $auth -o /tmp/$package.rpm "$rpm_url"
  rpm -i /tmp/$package.rpm
  result=$?
  if [[ -z "$s3_url" && "$result" != "0" ]]; then
    echo "RPM install (for $package) result code: $result"
  fi
else
  if [[ ! -z  "$s3_url" ]]; then
    echo "Falling back to use $s3_url for installation"
    curl -k -L -o /tmp/$package.rpm "$s3_url"
    rpm -i /tmp/$package.rpm
    result=$?
    if [ "$result" != "0" ]; then
      echo "RPM install (for $package) result code: $result"
    fi
  else
    echo "No s3 fallback url provided for package installation."
  fi
fi

if [[ -f "/tmp/$package.rpm" ]]; then
  rm -rf /tmp/$package.rpm
fi
if [[ -f "/tmp/artifacts.txt" ]]; then
  rm -rf /tmp/artifacts.txt
fi
is_rpm_package_installed=$(is_component_installed $rpm_package)
if [[ "$is_rpm_package_installed" == "0" ]]; then
  echo "Component $rpm_package has been installed."
else
  echo "Component $rpm_package has not been installed."
  exit 1
fi