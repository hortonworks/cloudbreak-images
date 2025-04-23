#!/bin/bash

set -ex -o pipefail

SELINUX_CDP_DIR=/etc/selinux/cdp
LOG_FILE=/var/log/selinux/install-cdp-policies.log

log() {
  echo "$(date +"%F-%T") $*" >> "$LOG_FILE"
}

install_policy() {
  local dir_abs_path="$1"
  local policy_name="$2"

  if ! semodule -l | grep -q "$policy_name"; then
    log "Installing CDP SELinux policy '$policy_name' from $dir_abs_path"
    make -f /usr/share/selinux/devel/Makefile "$policy_name.pp" -C "$dir_abs_path"
    log "Compiled CDP SELinux policy '$policy_name'"
    semodule -i "$dir_abs_path/$policy_name.pp" -v
    log "Installed CDP SELinux policy '$policy_name'"
  else
    log "CDP SELinux policy '$policy_name' already installed. Skipping installation."
    log "To reinstall, please remove the existing policy first: 'semodule -r $policy_name'"
  fi
}

apply_file_contexts() {
  local dir_abs_path="$1"
  local policy_name="$2"

  if [[ -f "$dir_abs_path/$policy_name.restorecon" ]]; then
    log "Applying file contexts for CDP SELinux policy '$policy_name'"
    local paths
    mapfile -t paths < <(grep -v '^[[:space:]]*$' "$dir_abs_path/$policy_name.restorecon")
    local path
    for path in "${paths[@]}"; do
      log "Applying file contexts to path '$path'"
      restorecon -RvFi "$path"
    done
    log "Applied file contexts for CDP SELinux policy '$policy_name'"
  else
    log "No .restorecon file found for CDP SELinux policy '$policy_name'. Skipping file context application."
  fi
}

apply_port_contexts() {
  local dir_abs_path="$1"
  local policy_name="$2"

  if [[ -f "$dir_abs_path/$policy_name.portcon" ]]; then
    log "Applying port contexts for CDP SELinux policy '$policy_name'"
    local ports
    mapfile -t ports < <(grep -v '^[[:space:]]*$' "$dir_abs_path/$policy_name.portcon")
    local port
    for port in "${ports[@]}"; do
      local port_type
      local port_protocol
      local port_number
      port_type=$(echo "$port" | awk '{print $1}')
      port_protocol=$(echo "$port" | awk '{print $2}')
      port_number=$(echo "$port" | awk '{print $3}')
      log "Applying port context using entry '$port'. Type='$port_type', protocol='$port_protocol', number='$port_number'."
      semanage port -a -t "$port_type" -p $port_protocol $port_number
    done
    log "Applied port contexts for CDP SELinux policy '$policy_name'"
  else
    log "No .portcon file found for CDP SELinux policy '$policy_name'. Skipping port context application."
  fi
}

main() {
  local CDP_POLICY_COMMON=common
  # Collect the directories containing CDP SELinux policy files
  mapfile -t CDP_POLICY_DIRS < <(find "$SELINUX_CDP_DIR" -mindepth 1 -maxdepth 1 -type d \! -name "$CDP_POLICY_COMMON" -exec basename {} \;)
  log "Found CDP SELinux policy directories: $CDP_POLICY_COMMON ${CDP_POLICY_DIRS[*]}"

  local dir
  for dir in "$CDP_POLICY_COMMON" "${CDP_POLICY_DIRS[@]}"; do
    local POLICY_NAME="cdp-$dir"

    install_policy "$SELINUX_CDP_DIR/$dir" "$POLICY_NAME"
    apply_file_contexts "$SELINUX_CDP_DIR/$dir" "$POLICY_NAME"
    apply_port_contexts "$SELINUX_CDP_DIR/$dir" "$POLICY_NAME"
  done
}

main "$@"
