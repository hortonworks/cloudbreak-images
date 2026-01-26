#!/bin/bash

set -e

install_rpm() {
  echo Installing $1 ...
  rpm -iv $1
}

install_rpms() {

  echo "Cleaning URLs from $PRE_WARM_RPMS"
  CLEANED=$(echo "$PRE_WARM_RPMS" | sed 's/\[//g' | sed 's/\]//g' | sed 's/\"//g')
  echo "Cleaned URL list: $CLEANED "
  IFS=',' read -ra URLS <<< "$CLEANED"

  for URL in "${URLS[@]}"; do 
    # remove possible surrounding quotes 
    RPM="${URL%\"}"
    RPM="${RPM#\"}" 
    install_rpm $RPM
  done
}

main() {

  if [[ -n "$PRE_WARM_RPMS" ]]; then
    if [[ "$PRE_WARM_RPMS" == *".rpm"* ]]; then 
      install_rpms
    else
      echo "No RPM files provided for this build by the composite - skipping."
    fi
  else
    echo "List of RPMs is empty - it might or might not be a problem, depending on the Runtime version - skipping."
  fi
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
