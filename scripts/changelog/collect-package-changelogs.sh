#!/bin/bash

set -e
[[ $DEBUG ]] && set -x

if [ -z "${IMAGE_UUID}" ] ; then
  echo "IMAGE_UUID env variable is mandatory"
  exit 1
fi

BASE_PATH="/tmp/changelogs-tmp"
RPM_PACKAGE_LIST_PATH="${BASE_PATH}/rpm-packages.txt"
RPM_PACKAGE_TAR_FILE_NAME="rpm-package-changelogs.tar.gz"
RPM_PACKAGE_TAR_FILE_PATH="${BASE_PATH}/${RPM_PACKAGE_TAR_FILE_NAME}"
CHANGELOG_DIRECTORY_NAME="${IMAGE_UUID}-changelogs"
CHANGELOG_BASE_PATH="${BASE_PATH}/${CHANGELOG_DIRECTORY_NAME}"

FILTERED_RPM_PACKAGES=("gpg-pubkey")

function execute() {
  echo "Cleaning up the temporary folders and files..."
  clean_up
  echo "Collecting installed rpm packages..."
  collect_rpm_packages
  echo "Storing changelogs to file by rpm package name..."
  store_rpm_package_changelog_to_file
  echo "Compressing the entire directory that contains generated files into ${RPM_PACKAGE_TAR_FILE_PATH} file..."
  cd $BASE_PATH
  tar -zcf $RPM_PACKAGE_TAR_FILE_NAME $CHANGELOG_DIRECTORY_NAME
  chmod 777 $BASE_PATH -R
}

function clean_up() {
  rm -rf $BASE_PATH
} 

function collect_rpm_packages() {
  mkdir -p $BASE_PATH
  rpm -qa | sort | while read line ; do
    name=$(rpm -q --queryformat '%{NAME}' "$line")
    if ! contains "$name" "${FILTERED_RPM_PACKAGES[@]}" ; then
      echo $name >> "$RPM_PACKAGE_LIST_PATH"
    else
      echo "Filterable package found: ${line}"
    fi
  done
  RPM_PACKAGE_NUMBER=$(wc -l < "$RPM_PACKAGE_LIST_PATH")
  echo "Found ${RPM_PACKAGE_NUMBER} rpm related package(s)"
  echo "The list of installed rpm packages was saved under ${RPM_PACKAGE_LIST_PATH}"
}

function store_rpm_package_changelog_to_file() {
  if [ -f $RPM_PACKAGE_LIST_PATH ] ; then
    mkdir -p $CHANGELOG_BASE_PATH
    while read package; do
      rpm -q --changelog $package > "${CHANGELOG_BASE_PATH}/${package}-changelog.txt"
    done < "$RPM_PACKAGE_LIST_PATH"
  else
    echo "No such packages were found, so nothing can be stored"
  fi
  RPM_PACKAGE_CHANGELOG_NUMBER=$(ls ${CHANGELOG_BASE_PATH} | wc -l)
  echo "Generated ${RPM_PACKAGE_CHANGELOG_NUMBER} changelog file(s)"
}

function contains() {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

echo "Trying to collect changelogs regarding to the installed packages on ${OS}"

case ${OS} in
  centos|redhat|amazon)
    execute
    ;;
  debian|ubuntu|suse)
    echo "Platform does not support this functionality"
    exit 1
    ;;
  *)
    echo "Unsupported platform:" $OS
    exit 1
    ;;
esac
