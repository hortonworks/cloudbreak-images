#!/bin/bash

set -ex -o pipefail

SELINUX_CDP_DIR=/etc/selinux/cdp
LOG_FILE=/var/log/selinux/install-cdp-policies.log

source /etc/selinux/cdp/policy-install-utils.sh

main() {
  log "$LOG_FILE" "The security context of this script's process is '$(id -Z)'"

  local CDP_POLICY_COMMON=common
  # Collect the directories containing CDP SELinux policy files
  mapfile -t CDP_POLICY_DIRS < <(find "$SELINUX_CDP_DIR" -mindepth 1 -maxdepth 1 -type d \! -name "$CDP_POLICY_COMMON" -exec basename {} \;)
  log "$LOG_FILE" "Found CDP SELinux policy directories: $CDP_POLICY_COMMON ${CDP_POLICY_DIRS[*]}"

  local dir
  for dir in "$CDP_POLICY_COMMON" "${CDP_POLICY_DIRS[@]}"; do
    local POLICY_NAME="cdp-$dir"

    install_policy "$SELINUX_CDP_DIR/$dir" "$POLICY_NAME" "$LOG_FILE"
    apply_file_contexts "$SELINUX_CDP_DIR/$dir" "$POLICY_NAME" "$LOG_FILE"
    apply_port_contexts "$SELINUX_CDP_DIR/$dir" "$POLICY_NAME" "$LOG_FILE"
  done
}

main "$@"
