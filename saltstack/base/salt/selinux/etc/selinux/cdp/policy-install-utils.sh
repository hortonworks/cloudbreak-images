#!/bin/bash

log() {
  local log_file="$1"
  mkdir -p "$(dirname "$log_file")"
  touch -a "$log_file"
  shift
  echo "$(date +"%F-%T") $*" >> "$log_file"
}

install_policy() {
  local dir_abs_path="$1"
  local policy_name="$2"
  local log_file="$3"

  if ! semodule -l | grep -q "$policy_name"; then
    log "$log_file" "Installing CDP SELinux policy '$policy_name' from $dir_abs_path"

    make -f /usr/share/selinux/devel/Makefile "$policy_name.pp" -C "$dir_abs_path" SHELL='sh -x'
    log "$log_file" "Compiled CDP SELinux policy '$policy_name'"

    semodule -i "$dir_abs_path/$policy_name.pp" -v
    log "$log_file" "Installed CDP SELinux policy '$policy_name'"

    make -f /usr/share/selinux/devel/Makefile clean -C "$dir_abs_path" SHELL='sh -x'
    log "$log_file" "Cleaned up temporary files for CDP SELinux policy '$policy_name'"
  else
    log "$log_file" "CDP SELinux policy '$policy_name' already installed. Skipping installation."
    log "$log_file" "To reinstall, please remove the existing policy first: 'semodule -r $policy_name'"
  fi

  if [[ "$policy_name" == "cdp-common" ]]; then
    log "$log_file" "Copying the cdp-common modules's interfaces to the system SELinux include directory."
    mkdir -p /usr/share/selinux/devel/include/cdp
    cp -vn "$dir_abs_path/$policy_name.if" "/usr/share/selinux/devel/include/cdp/$policy_name.if"
  fi
}

apply_file_contexts() {
  local dir_abs_path="$1"
  local policy_name="$2"
  local log_file="$3"

  if [[ -f "$dir_abs_path/$policy_name.restorecon" ]]; then
    log "$log_file" "Applying file contexts for CDP SELinux policy '$policy_name'"
    local paths
    mapfile -t paths < <(grep -v '^[[:space:]]*$' "$dir_abs_path/$policy_name.restorecon")
    local path
    for path in "${paths[@]}"; do
      log "$log_file" "Applying file contexts to path '$path'"
      restorecon -RvFi "$path"
    done
    log "$log_file" "Applied file contexts for CDP SELinux policy '$policy_name'"
  else
    log "$log_file" "No .restorecon file found for CDP SELinux policy '$policy_name'. Skipping file context application."
  fi
}

apply_port_contexts() {
  local dir_abs_path="$1"
  local policy_name="$2"
  local log_file="$3"

  if [[ -f "$dir_abs_path/$policy_name.portcon" ]]; then
    log "$log_file" "Applying port contexts for CDP SELinux policy '$policy_name'"
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
      log "$log_file" "Applying port context using entry '$port'. Type='$port_type', protocol='$port_protocol', number='$port_number'."
      semanage port -a -t "$port_type" -p "$port_protocol" "$port_number"
    done
    log "$log_file" "Applied port contexts for CDP SELinux policy '$policy_name'"
  else
    log "$log_file" "No .portcon file found for CDP SELinux policy '$policy_name'. Skipping port context application."
  fi
}
