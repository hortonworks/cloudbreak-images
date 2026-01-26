#!/bin/bash

set -ex

check_prerequisites() {
  : ${PRE_WARM_RPMS:? required}
}

install_rpm() {
  echo Installing $1 ...
  #rpm -i $1
}

install_rpms() {

  CLEANED=$(echo "$PRE_WARM_RPMS" | sed 's/ \[\|\] //g' \ | sed 's/\\"//g')
  IFS=',' read -ra URLS <<< "$CLEANED"
  for URL in "${URLS[@]}"; do 
    # remove surrounding quotes 
    RPM="${URL%\"}"
    RPM="${RPM#\"}" 
    install_rpm $RPM
  done
}

main() {
 
  echo $PRE_WARM_RPMS
  check_prerequisites
  install_rpms
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
