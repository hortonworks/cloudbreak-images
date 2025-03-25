#!/bin/bash

set -ex -o pipefail

export LUKS_VOLUME_NAME="cdp-luks"
export MOUNT_POINT="/mnt/$LUKS_VOLUME_NAME"
export LUKS_DIR="/etc/$LUKS_VOLUME_NAME"
export LUKS_BACKING_FILE="$LUKS_DIR/$LUKS_VOLUME_NAME"
export PASSPHRASE_TMPFS="/mnt/cdp-luks_passphrase_tmpfs"
export PASSPHRASE_TMPFS_SIZE="16k"
export PASSPHRASE_PLAINTEXT="$PASSPHRASE_TMPFS/passphrase"
export PASSPHRASE_CIPHERTEXT="$LUKS_DIR/passphrase_ciphertext"
export LUKS_LOG_DIR="/var/log/$LUKS_VOLUME_NAME"
export LUKS_MAPPER_DEVICE="/dev/mapper/$LUKS_VOLUME_NAME"
export ENCRYPTION_KEY_FILE="$LUKS_DIR/passphrase_encryption_key"
{% if pillar['CUSTOM_IMAGE_TYPE'] == 'freeipa' %}
export IS_FREEIPA=true
{% else %}
export IS_FREEIPA=false
{% endif %}
export AWS_USE_FIPS_ENDPOINT=true
export AWS_RETRY_MODE=standard
export AWS_MAX_ATTEMPTS=15

log() {
  echo "$(date +"%F-%T") $*"
}

recreate_loop_device() {
  if [[ $(losetup -j "$LUKS_BACKING_FILE" | wc -l | tr -d '\n') == 0 ]]; then
    # Recreate the loop device
    log "Recreating loop device"
    LOOP_DEVICE=$(losetup --find --show "$LUKS_BACKING_FILE")

    if [[ $(losetup -j "$LUKS_BACKING_FILE" | cut -d ':' -f1 | tr -d '\n') != "$LOOP_DEVICE" ]]; then
      log "Failed to set up loop device correctly... Exiting LUKS volume reopen script with failed exit code!"
      exit 1
    fi
  else
    log "Found existing loop device"
    LOOP_DEVICE=$(losetup -j "$LUKS_BACKING_FILE" | cut -d ':' -f1 | tr -d '\n')
  fi
  log "Allocated loop device: $LOOP_DEVICE"
}

setup_tmpfs_for_plaintext_passphrase() {
  if ! mountpoint "$PASSPHRASE_TMPFS"; then
    # Create the tmpfs for the plaintext passphrase
    log "Creating tmpfs for the plaintext passphrase"
    mount -t tmpfs -o size="$PASSPHRASE_TMPFS_SIZE",mode=700 tmpfs "$PASSPHRASE_TMPFS"
  fi
}

decrypt_passphrase_ciphertext() {
  if [[ ! -s "$PASSPHRASE_PLAINTEXT" ]]; then
    add_kms_entry_to_etc_hosts
    INSTANCE_ID="$(TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 10") && \
                                curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)"
    METADATA_LOG_FILE="$LUKS_LOG_DIR/passphrase_decryption_md-$(date +"%F-%T").json"
    # Decrypt the ciphertext passphrase
    log "Decrypting plaintext passphrase"
    if ! /usr/local/bin/aws-encryption-cli \
           -v -v -v -v \
           --decrypt \
           --input "$PASSPHRASE_CIPHERTEXT" \
           --output "$PASSPHRASE_PLAINTEXT" \
           --wrapping-keys provider=aws-kms key="$(cat "$ENCRYPTION_KEY_FILE")" \
           --metadata-output "$METADATA_LOG_FILE" \
           --encryption-context INSTANCE_ID="$INSTANCE_ID"; then
      log "Failed to decrypt the plaintext ciphertext... Exiting LUKS volume reopen script with failed exit code!"
      restore_etc_hosts
      exit 2
    fi
    restore_etc_hosts
    chmod 600 "$PASSPHRASE_PLAINTEXT"
    chmod 600 "$METADATA_LOG_FILE"
  fi
}

add_kms_entry_to_etc_hosts() {
  if [[ "$IS_FREEIPA" == "true" ]]; then
    REGION="$(TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 10") && \
        curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')"
    KMS_FIPS_ENDPOINT="kms-fips.$REGION.amazonaws.com"
    AMAZON_PROVIDED_DNS_SERVER="169.254.169.253"

    # Get the DNS servers from the network connection
    IFS=" | " read -ra DNS_SERVERS <<< "$(nmcli -g IP4.DNS connection show "$(nmcli -g GENERAL.CONNECTION device show eth0)")"
    # Prepend the Amazon provided DNS server to the list of DNS servers
    DNS_SERVERS=("$AMAZON_PROVIDED_DNS_SERVER" "${DNS_SERVERS[@]}")

    log "DNS servers available for resolving KMS endpoint: ${DNS_SERVERS[*]}"
    for dns_server in "${DNS_SERVERS[@]}"; do
      log "Trying to resolve $KMS_FIPS_ENDPOINT using DNS server $dns_server"
      set +e
      KMS_IP_ADDRESS="$(temp="$(dig @"$dns_server" "$KMS_FIPS_ENDPOINT" +noall +short)" && echo "$temp")"
      set -e
      if [[ -n "$KMS_IP_ADDRESS" ]]; then
        log "Successfully resolved $KMS_FIPS_ENDPOINT using DNS server $dns_server"
        break
      fi
    done

    if [[ -z "$KMS_IP_ADDRESS" ]]; then
      log "Failed to resolve $KMS_FIPS_ENDPOINT with any DNS server... Exiting LUKS volume reopen script with failed exit code!"
      exit 5
    fi

    # Add entry to /etc/hosts while creating a backup of the original file
    log "Adding temporary entry \"$KMS_IP_ADDRESS $KMS_FIPS_ENDPOINT\" to /etc/hosts ..."
    sed -i.bak "\$a$KMS_IP_ADDRESS $KMS_FIPS_ENDPOINT" /etc/hosts
  else
    log "No need to add temporary KMS entry to /etc/hosts since this is not a FreeIPA instance."
  fi
}

restore_etc_hosts() {
  if [[ "$IS_FREEIPA" == "true" ]]; then
    # Restore the original /etc/hosts file from the backup file
    log "Restoring /etc/hosts from the backup file..."
    mv -f /etc/hosts.bak /etc/hosts
  else
    log "No need to restore /etc/hosts since no temporary entry was added to it as this is not a FreeIPA instance."
  fi
}

reopen_luks_volume() {
  if ! cryptsetup status "$LUKS_VOLUME_NAME"; then
    # Reopen the LUKS volume
    log "Reopening LUKS volume"
    if ! cryptsetup open "$LOOP_DEVICE" "$LUKS_VOLUME_NAME" \
             --key-file "$PASSPHRASE_PLAINTEXT" \
             --type luks2 \
             --debug; then
      log "Failed to reopen the LUKS volume... Exiting LUKS volume reopen script with failed exit code!"
      exit 3
    fi
  fi
}

remount_luks_volume() {
  if ! mountpoint "$MOUNT_POINT"; then
    # Remount the LUKS volume
    log "Remounting LUKS volume"
    mount "$LUKS_MAPPER_DEVICE" "$MOUNT_POINT"
    chmod 755 "$MOUNT_POINT"
  else
    log "Did not mount the LUKS volume, as the path is already a mount point... Exiting LUKS volume reopen script with failed exit code!"
    exit 4
  fi
}

main() {
  log "$(basename $0) Start"

  recreate_loop_device
  setup_tmpfs_for_plaintext_passphrase
  decrypt_passphrase_ciphertext
  reopen_luks_volume
  remount_luks_volume

  log "$(basename $0) Finish"
}

main
