#!/bin/bash

set -e
[[ $DEBUG ]] && set -x

BASE_RPM_PACKAGE_LIST_PATH=/tmp/base-rpm-packages.txt
COMPLETE_RPM_PACKAGE_LIST_PATH=/tmp/complete-rpm-packages.txt
DELTA_RPM_PACKAGE_LIST_PATH=/tmp/delta-rpm-packages.txt
PYTHON_PACKAGE_LIST_PATH=/tmp/python-packages.txt
VIRTUALENV_PYTHON_PACKAGE_LIST_PATH=/tmp/virtualenv-python-packages.txt
HARDCODED_PACKAGE_LIST_PATH=/tmp/hardcoded-packages.csv
INSTALLED_DELTA_PACKAGE_LIST_PATH=/tmp/installed-delta-packages.csv
INSTALLED_FULL_PACKAGE_LIST_PATH=/tmp/installed-full-packages.csv

BASE_STATE="base"
COMPLETE_STATE="complete"

SOURCE_RPM="Package manager"
SOURCE_PYTHON="Python pip"
SOURCE_PARCEL="Parcel"

CLOUDERA_URL="cloudera.com"

HEADER="NAME;VERSION;SOURCE;LICENSE;VENDOR;URL;SUMMARY"

FILTERED_RPM_PACKAGES=("gpg-pubkey")

REQUIRED_KEY_LIST=("Name" "Version" "Summary" "Home-page" "Author" "License")

declare -a DELTA_CSV_ARRAY=()
declare -a FULL_CSV_ARRAY=()
declare -a PYTHON_PACKAGE_ARRAY=()
declare -a PARCEL_LIST=()

function execute() {
  if [ -z "${INSTALLATION_STATE}" ] ; then
    echo "INSTALLATION_STATE env variable is mandatory"
    exit 0
  fi
  if [ "${INSTALLATION_STATE}" == $BASE_STATE ] ; then
    collect_rpm_packages $BASE_RPM_PACKAGE_LIST_PATH
  elif [ "${INSTALLATION_STATE}" == $COMPLETE_STATE ] ; then
    collect_rpm_packages $COMPLETE_RPM_PACKAGE_LIST_PATH
    collect_python_packages $PYTHON_PACKAGE_LIST_PATH
    collect_virtualenv_python_packages $VIRTUALENV_PYTHON_PACKAGE_LIST_PATH
    check_parcels
    check_hardcoded_packages
    get_rpm_differences
    construct_detailed_packages_csv
  else
    echo "Unsupported installation state:" $INSTALLATION_STATE
    exit 0
  fi
}

function collect_rpm_packages() {
  file=$1
  echo "Collecting installed rpm packages"
  rpm -qa | sort | while read line ; do
    name=$(rpm -q --queryformat '%{NAME}' "$line")
    if ! contains "$name" "${FILTERED_RPM_PACKAGES[@]}" ; then
      echo $name >> "$file"
    else
      echo "Filterable package found: ${line}"
    fi
  done
  cat "$file"
  RPM_PACKAGE_NUMBER=$(wc -l < "$file")
  echo "Found ${RPM_PACKAGE_NUMBER} rpm related package(s)"
  echo "The list of installed rpm packages was saved under ${file}"
}

function collect_python_packages() {
  file=$1
  echo "Collecting installed python packages"
  python3 -m pip list --format json | jq -r '.[].name' | sort >> "$file"
  cat "$file"
  PYTHON_PACKAGE_NUMBER=$(wc -l < "$file")
  echo "Found ${PYTHON_PACKAGE_NUMBER} python related package(s)"
  echo "The list of installed python packages was saved under ${file}"
}

function collect_virtualenv_python_packages() {
  file=$1
  echo "Collecting installed python packages in virtualenv used by Salt"
  python3 -m virtualenv ${SALT_PATH}
  source ${SALT_PATH}/bin/activate
  python3 -m pip list --format json | jq -r '.[].name' | sort >> "$file"
  cat "$file"
  PYTHON_PACKAGE_NUMBER=$(wc -l < "$file")
  echo "Found ${PYTHON_PACKAGE_NUMBER} python related package(s) in virtualenv"
  echo "The list of installed virtualenv python packages was saved under ${file}"
  deactivate
}

function check_parcels() {
  echo "Checking prewarmed parcels"
  numPrewarm=0
  if [ -z "${PRE_WARM_PARCELS}" ] ; then
    echo "PRE_WARM_PARCELS is undefined"
  else
    numPrewarm=$(echo "${PRE_WARM_PARCELS}" | jq '. | length')
  fi
  numCsd=0
  if [ -z "${PRE_WARM_CSD}" ] ; then
    echo "PRE_WARM_CSD is undefined"
  else
    numCsd=$(echo "${PRE_WARM_CSD}" | jq '. | length')
  fi
  numCdh=0
  if [ -z "${PARCELS_NAME}" ] ; then
    echo "PARCELS_NAME is undefined"
  else
    numCdh=1
  fi
  if [ -z "${STACK_BASEURL}" ] ; then
    echo "STACK_BASEURL is undefined"
  fi

  sum=$(( $numPrewarm + $numCsd + $numCdh ))
  echo "Found ${sum} prewarmed parcel(s)"
}

function check_hardcoded_packages() {
  echo "Checking the hardcoded packages in the predefined file ${HARDCODED_PACKAGE_LIST_PATH}"
  if [ ! -f $HARDCODED_PACKAGE_LIST_PATH ] ; then
    echo "The file containing the hardcoded packages could not be found under: " $HARDCODED_PACKAGE_LIST_PATH
  else
    HARDCODED_PACKAGE_NUMBER=$(wc -l < "$HARDCODED_PACKAGE_LIST_PATH")
    echo "Found ${HARDCODED_PACKAGE_NUMBER} hardcoded package(s)"
  fi
}

function get_rpm_differences() {
  check_rpm_file $BASE_RPM_PACKAGE_LIST_PATH false
  check_rpm_file $COMPLETE_RPM_PACKAGE_LIST_PATH false

  echo "Determining the difference between the base and complete rpm package lists"
  grep -Fxvf $BASE_RPM_PACKAGE_LIST_PATH $COMPLETE_RPM_PACKAGE_LIST_PATH | sort > "$DELTA_RPM_PACKAGE_LIST_PATH"
  check_rpm_file $DELTA_RPM_PACKAGE_LIST_PATH true
  RPM_PACKAGE_DIFF_NUMBER=$(wc -l < "$DELTA_RPM_PACKAGE_LIST_PATH")
  echo "Found ${RPM_PACKAGE_DIFF_NUMBER} difference(s) between rpm packages"
  echo "Rpm package differences are saved under ${DELTA_RPM_PACKAGE_LIST_PATH}"
}

function add_rpm_package_to_csv_list() {
  local package=$1
  local isDelta=$2
  RPM_PACKAGE_DETAIL=$(echo $(rpm -q --queryformat "%{NAME}|%{VERSION}|$SOURCE_RPM|%{LICENSE}|%{VENDOR}|%{URL}|%{SUMMARY}" "$package") | sed -e "s/;/,/g")
  RPM_PACKAGE_DETAIL=$(echo $RPM_PACKAGE_DETAIL | sed -e "s/|/;/g")
  if [ "$isDelta" = true ] ; then
    DELTA_CSV_ARRAY+=("$RPM_PACKAGE_DETAIL")
  else
    FULL_CSV_ARRAY+=("$RPM_PACKAGE_DETAIL")
  fi
}

function add_python_package_to_csv_list() {
  local package=$1
  declare -A DETAIL_MAP=()
  PIPCALL="pip"
  if [ "${OS}" == "redhat8" ] ; then
    PIPCALL="python3 -m pip"
  fi
  while IFS= read -r line ; do
    IFS=':' read -r key value <<< "$line"
    key=$(echo ${key} | sed -e 's/^[ \t]*//')
    if contains "$key" "${REQUIRED_KEY_LIST[@]}" ; then
      if [[ -z ${DETAIL_MAP[$key]} ]] ; then
        value=$(echo ${value} | sed -e 's/^[ \t]*//')
        DETAIL_MAP[$key]=$value
      fi
    fi
  done <<< "$(python3 -m pip show -v "$package")"
  PYTHON_PACKAGE_DETAIL="${DETAIL_MAP["Name"]}|${DETAIL_MAP["Version"]}|$SOURCE_PYTHON|${DETAIL_MAP["License"]}|${DETAIL_MAP["Author"]}|${DETAIL_MAP["Home-page"]}|${DETAIL_MAP["Summary"]}"
  PYTHON_PACKAGE_DETAIL=$(echo $PYTHON_PACKAGE_DETAIL | sed -e "s/;/,/g")
  PYTHON_PACKAGE_DETAIL=$(echo $PYTHON_PACKAGE_DETAIL | sed -e "s/|/;/g")
  unset DETAIL_MAP
  DELTA_CSV_ARRAY+=("$PYTHON_PACKAGE_DETAIL")
  FULL_CSV_ARRAY+=("$PYTHON_PACKAGE_DETAIL")
}

function add_parcel_to_csv_list() {
  local fullparcel=$1
  local url=$2
  
  IFS='-' read -r -a array <<< "$fullparcel"
  name=${array[0]}
  version=${array[1]}

  # Add GBN to the version if specified
  if find_substring "$url" "$CLOUDERA_URL" ; then
    pattern="([0-9]{7,})"
    if [[ "$url" =~ $pattern ]] ; then 
      version="${version}-${BASH_REMATCH[1]}"
    fi
  fi
   
  if ! contains "$name" "${PARCEL_LIST[@]}" ; then
    PARCEL_LIST+=("$name")
    case "$url" in
      *.jar)
        ;;
      */.)
        url="${url//"/."/"/"}"
        url+="${fullparcel}"
        ;;
      */)
        url+="${fullparcel}"
        ;;
      *)
        url+="/${fullparcel}"
        ;;
    esac
    PARCEL_DETAIL=$(echo "${name}|${version}|${SOURCE_PARCEL}|Cloudera Standard License|Cloudera Inc.|${url}|UNKNOWN" | sed -e "s/;/,/g")
    PARCEL_DETAIL=$(echo $PARCEL_DETAIL | sed -e "s/|/;/g")
    DELTA_CSV_ARRAY+=("$PARCEL_DETAIL")
    FULL_CSV_ARRAY+=("$PARCEL_DETAIL")
  fi
}

function construct_detailed_packages_csv {
  # Construct csv from the rpm package list
  echo "Constructing the detailed delta rpm packages csv format"
  while read package; do
    add_rpm_package_to_csv_list "$package" true
  done < "$DELTA_RPM_PACKAGE_LIST_PATH"
  echo "Constructing the detailed full rpm packages csv format"
  while read package; do
    add_rpm_package_to_csv_list "$package" false
  done < "$COMPLETE_RPM_PACKAGE_LIST_PATH"

  # Construct csv from the python package list
  echo "Constructing the detailed python packages csv format"
  if [ -f $PYTHON_PACKAGE_LIST_PATH ] ; then
    while read package; do
      PYTHON_PACKAGE_ARRAY+=("$package")
      add_python_package_to_csv_list "$package"
    done < "$PYTHON_PACKAGE_LIST_PATH"
  fi
  if [ -f $VIRTUALENV_PYTHON_PACKAGE_LIST_PATH ] ; then
    python3 -m virtualenv ${SALT_PATH}
    source ${SALT_PATH}/bin/activate
    while read package; do
      if ! contains "$package" "${PYTHON_PACKAGE_ARRAY[@]}" ; then
        PYTHON_PACKAGE_ARRAY+=("$package")
        add_python_package_to_csv_list "$package"
      fi
    done < "$VIRTUALENV_PYTHON_PACKAGE_LIST_PATH"
    deactivate
  fi

  # Construct csv from the parcel list
  echo "Constructing the detailed parcels csv format"
  if [ ! -z "${PRE_WARM_PARCELS}" ] ; then
    for entry in $(echo "${PRE_WARM_PARCELS}" | jq -r '.[] | @base64'); do
      add_parcel_to_csv_list $(echo ${entry} | base64 --decode | jq -r '.[0]') $(echo ${entry} | base64 --decode | jq -r '.[1]')
    done
  fi
  if [ ! -z "${PRE_WARM_CSD}" ] ; then
    for entry in $(echo "${PRE_WARM_CSD}" | jq -r '.[]'); do
      add_parcel_to_csv_list ${entry##*/} $entry
    done
  fi
  if [ ! -z "${PARCELS_NAME}" ] ; then
    add_parcel_to_csv_list "$PARCELS_NAME" "$STACK_BASEURL"
  fi

  # Add the hardcoded package list to csv
  echo "Appending the hardcoded packages to the previous csv list"
  if [ -f $HARDCODED_PACKAGE_LIST_PATH ] ; then
    while read package; do
      DELTA_CSV_ARRAY+=("$package")
      FULL_CSV_ARRAY+=("$package")
    done < "$HARDCODED_PACKAGE_LIST_PATH"
  fi

  # Merge the different lines into one file
  echo "Merging the generated csv detailed rows"
  merge_packages "$INSTALLED_DELTA_PACKAGE_LIST_PATH" "${DELTA_CSV_ARRAY[@]}"
  merge_packages "$INSTALLED_FULL_PACKAGE_LIST_PATH" "${FULL_CSV_ARRAY[@]}"
}

function merge_packages() {
  local output=$1
  shift
  local array=("$@")

  IFS=$'\n' sorted=($(sort <<<"${array[*]}"))
  unset IFS
  printf "%s\n" "${HEADER}" >> "$output"
  printf "%s\n" "${sorted[@]}" >> "$output"

  if [ -f $output ] ; then
    echo "Final detailed package list was saved under ${output}"
    chmod 644 "$output"
  else
    echo "Final detailed package file not found: " $output
  fi
}

function check_rpm_file() {
  file=$1
  delta_file=$2
  if [ ! -f $file ] ; then
    if [ "$delta_file" = true ] ; then
      echo "The result delta package file not found: " $file
    else
      echo "It is not possible to generate the difference. Package file not found: " $file
    fi
    exit 0
  fi
}

function find_substring() {
  local str=$1
  local sub=$2
  if [[ "$str" == *"$sub"* ]] ; then
    return 0
  fi
  return 1
}

function contains() {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

echo "Trying to collect installed packages on ${SALT_INSTALL_OS}"

case ${SALT_INSTALL_OS} in
  centos|redhat)
    execute
    ;;
  debian|ubuntu)
    echo "Platform does not support this functionality"
    exit 0
    ;;
  amazon)
    execute
    ;;
  suse)
    echo "Platform does not support this functionality"
    exit 0
    ;;
  *)
    echo "Unsupported platform:" $SALT_INSTALL_OS
    exit 0
    ;;
esac
