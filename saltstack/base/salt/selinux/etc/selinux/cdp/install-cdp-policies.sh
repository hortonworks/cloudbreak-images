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

  # Exact names: a substring match would treat e.g. cdp-ipa as installed when cdp-ipahealthagent is.
  local installed
  installed=$(semodule -l | awk '{print $1}')

  # Compile everything first (cdp-common first: the others include its interfaces), then install all
  # new modules in ONE semodule transaction: each semodule/semanage call rebuilds the whole policy.
  local dir policy_dirs=() compiled=() pp_files=()
  for dir in "$CDP_POLICY_COMMON" "${CDP_POLICY_DIRS[@]}"; do
    local POLICY_NAME="cdp-$dir"
    policy_dirs+=("$SELINUX_CDP_DIR/$dir" "$POLICY_NAME")
    if grep -qx -- "$POLICY_NAME" <<< "$installed"; then
      log "$LOG_FILE" "CDP SELinux policy '$POLICY_NAME' already installed. Skipping installation."
      log "$LOG_FILE" "To reinstall, please remove the existing policy first: 'semodule -r $POLICY_NAME'"
    else
      compile_policy "$SELINUX_CDP_DIR/$dir" "$POLICY_NAME" "$LOG_FILE"
      compiled+=("$dir")
      pp_files+=("$SELINUX_CDP_DIR/$dir/$POLICY_NAME.pp")
    fi
    copy_common_interfaces "$SELINUX_CDP_DIR/$dir" "$POLICY_NAME" "$LOG_FILE"
  done

  install_policies "$LOG_FILE" "${pp_files[@]}"
  for dir in "${compiled[@]}"; do
    cleanup_policy "$SELINUX_CDP_DIR/$dir" "cdp-$dir" "$LOG_FILE"
  done

  for dir in "$CDP_POLICY_COMMON" "${CDP_POLICY_DIRS[@]}"; do
    apply_file_contexts "$SELINUX_CDP_DIR/$dir" "cdp-$dir" "$LOG_FILE"
  done
  apply_port_contexts_batch "$LOG_FILE" "${policy_dirs[@]}"
}

main "$@"
