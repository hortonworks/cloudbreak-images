#!/bin/bash

set -ex -o pipefail

SELINUX_CDP_DIR=/etc/selinux/cdp

log() {
  echo "$(date +"%F-%T") $*"
}

install_policy() {
  local dir_abs_path="$1"
  local policy_name="$2"

  if ! semodule -l | grep -q "$policy_name"; then
    log "Installing CDP SELinux policy '$policy_name' from $dir_abs_path"
    make -f /usr/share/selinux/devel/Makefile "$policy_name.pp" -C "$dir_abs_path"
    log "Compiled CDP SELinux policy '$policy_name'"
    semodule -i "$dir_abs_path/$policy_name.pp"
    log "Installed CDP SELinux policy '$policy_name'"
  else
    log "CDP SELinux policy '$policy_name' already installed. Skipping installation."
  fi
}

apply_file_contexts() {
  local dir_abs_path="$1"
  local policy_name="$2"

  if [[ -f "$dir_abs_path/$policy_name.restorecon" ]]; then
    log "Applying file contexts for CDP SELinux policy '$policy_name'"
    mapfile -t paths < <(grep -v '^[[:space:]]*$' "$dir_abs_path/$policy_name.restorecon")
    for path in "${paths[@]}"; do
      log "Applying file contexts to path '$path'"
      restorecon -R -v -i "$path"
    done
    log "Applied file contexts for CDP SELinux policy '$policy_name'"
  else
    log "No restorecon file found for CDP SELinux policy '$policy_name'. Skipping file context application."
  fi
}

main() {
  # Collect the directories containing CDP SELinux policy files
  mapfile -t CDP_POLICY_DIRS < <(find "$SELINUX_CDP_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
  log "Found CDP SELinux policy directories: ${CDP_POLICY_DIRS[*]}"

  for dir in "${CDP_POLICY_DIRS[@]}"; do
    local POLICY_NAME="cdp-$dir"

    install_policy "$SELINUX_CDP_DIR/$dir" "$POLICY_NAME"
    apply_file_contexts "$SELINUX_CDP_DIR/$dir" "$POLICY_NAME"
  done
}

main "$@"
