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

# --- Batched install (install-cdp-policies.sh) -------------------------------------------------
# Every `semodule -i` and `semanage port` call rebuilds and reloads the whole system policy, which
# takes seconds each. Installing all CDP modules in one transaction (and all port contexts in
# another) gives the same result with far fewer rebuilds.

# Compiles <dir>/<name>.pp without installing it.
compile_policy() {
  local dir_abs_path="$1"
  local policy_name="$2"
  local log_file="$3"
  log "$log_file" "Compiling CDP SELinux policy '$policy_name' from $dir_abs_path"
  make -f /usr/share/selinux/devel/Makefile "$policy_name.pp" -C "$dir_abs_path" SHELL='sh -x'
  log "$log_file" "Compiled CDP SELinux policy '$policy_name'"
}

cleanup_policy() {
  local dir_abs_path="$1"
  local policy_name="$2"
  local log_file="$3"
  make -f /usr/share/selinux/devel/Makefile clean -C "$dir_abs_path" SHELL='sh -x'
  log "$log_file" "Cleaned up temporary files for CDP SELinux policy '$policy_name'"
}

# The other CDP modules include cdp-common's interfaces, so they must be in place before those compile.
copy_common_interfaces() {
  local dir_abs_path="$1"
  local policy_name="$2"
  local log_file="$3"
  if [[ "$policy_name" == "cdp-common" ]]; then
    log "$log_file" "Copying the cdp-common modules's interfaces to the system SELinux include directory."
    mkdir -p /usr/share/selinux/devel/include/cdp
    cp -vn "$dir_abs_path/$policy_name.if" "/usr/share/selinux/devel/include/cdp/$policy_name.if"
  fi
}

# Installs the given .pp files in a single semodule transaction.
install_policies() {
  local log_file="$1"
  shift
  if [[ $# -eq 0 ]]; then
    log "$log_file" "No CDP SELinux policy to install."
    return
  fi
  log "$log_file" "Installing $# CDP SELinux policies in one transaction: $*"
  semodule -v -i "$@"
  log "$log_file" "Installed $# CDP SELinux policies"
}

# Applies the .portcon entries of the given policies (pairs of DIR NAME) in a single semanage
# transaction. Entry format, one per line: <-a|-m> <port type> <protocol> <port number>.
apply_port_contexts_batch() {
  local log_file="$1"
  shift
  local commands
  commands=$(mktemp)
  while [[ $# -ge 2 ]]; do
    local dir_abs_path="$1" policy_name="$2"
    shift 2
    [[ -f "$dir_abs_path/$policy_name.portcon" ]] || continue
    local operation_type port_type port_protocol port_number
    # `|| [[ -n ... ]]`: also read a last line without a trailing newline (several .portcon files).
    while read -r operation_type port_type port_protocol port_number || [[ -n "$operation_type" ]]; do
      [[ -n "$operation_type" ]] || continue
      case "$operation_type" in
        -a|-m)
          log "$log_file" "Port context for '$policy_name': $operation_type type='$port_type' protocol='$port_protocol' number='$port_number'"
          echo "port $operation_type -t $port_type -p $port_protocol $port_number" >> "$commands"
          ;;
        *)
          log "$log_file" "Unknown operation type '$operation_type' in port context entry of '$policy_name'. Skipping."
          ;;
      esac
    done < "$dir_abs_path/$policy_name.portcon"
  done
  if [[ -s "$commands" ]]; then
    log "$log_file" "Applying $(wc -l < "$commands") port contexts in one transaction"
    semanage import -f "$commands"
    log "$log_file" "Applied port contexts"
  fi
  rm -f "$commands"
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
      local operation_type
      local port_type
      local port_protocol
      local port_number
      operation_type=$(echo "$port" | awk '{print $1}')
      port_type=$(echo "$port" | awk '{print $2}')
      port_protocol=$(echo "$port" | awk '{print $3}')
      port_number=$(echo "$port" | awk '{print $4}')

      case "$operation_type" in
        -a)
          log "$log_file" "Adding port context using entry '$port'. Type='$port_type', protocol='$port_protocol', number='$port_number'."
          semanage port -a -t "$port_type" -p "$port_protocol" "$port_number"
          ;;
        -m)
          log "$log_file" "Adding override for existing port context '$(semanage port -l | grep "$port_number")' using entry '$port'. Type='$port_type', protocol='$port_protocol', number='$port_number'."
          semanage port -m -t "$port_type" -p "$port_protocol" "$port_number"
          ;;
        *)
          log "$log_file" "Unknown operation type '$operation_type' in port context entry '$port'. Skipping."
          ;;
      esac
    done
    log "$log_file" "Applied port contexts for CDP SELinux policy '$policy_name'"
  else
    log "$log_file" "No .portcon file found for CDP SELinux policy '$policy_name'. Skipping port context application."
  fi
}
