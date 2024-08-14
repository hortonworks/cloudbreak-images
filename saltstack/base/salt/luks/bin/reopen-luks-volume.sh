#!/bin/bash

set -ex -o pipefail

export LUKS_VOLUME_NAME="cdp-luks"
export MOUNT_POINT="/mnt/$LUKS_VOLUME_NAME"
export LUKS_DIR="/etc/$LUKS_VOLUME_NAME"
export LUKS_BACKING_FILE="$LUKS_DIR/$LUKS_VOLUME_NAME"
export PASSPHRASE_TMPFS="/mnt/cdp-luks_passphrase_tmpfs"
export PASSPHRASE_PLAINTEXT="$PASSPHRASE_TMPFS/passphrase"
export PASSPHRASE_CIPHERTEXT="$LUKS_DIR/passphrase_ciphertext"
export LUKS_LOG_DIR="/var/log/$LUKS_VOLUME_NAME"
export LUKS_MAPPER_DEVICE="/dev/mapper/$LUKS_VOLUME_NAME"
export ENCRYPTION_KEY_FILE="$LUKS_DIR/passphrase_encryption_key"

export AWS_USE_FIPS_ENDPOINT=true

recreate_loop_device() {
  if [[ $(losetup -j "$LUKS_BACKING_FILE" | wc -l | tr -d '\n') == 0 ]]; then
    # Recreate the loop device
    LOOP_DEVICE=$(losetup --find --show "$LUKS_BACKING_FILE")

    if [[ $(losetup -j "$LUKS_BACKING_FILE" | cut -d ':' -f1 | tr -d '\n') != "$LOOP_DEVICE" ]]; then
      echo "Failed to set up loop device correctly... Exiting LUKS volume reopen script with failed exit code!"
      exit 1
    fi
  else
    LOOP_DEVICE=$(losetup -j "$LUKS_BACKING_FILE" | cut -d ':' -f1 | tr -d '\n')
  fi
}

setup_tmpfs_for_plaintext_passphrase() {
  if ! mountpoint "$PASSPHRASE_TMPFS"; then
    # Create the tmpfs for the plaintext passphrase
    mount -t tmpfs -o size=1k,mode=700 tmpfs "$PASSPHRASE_TMPFS"
  fi
}

decrypt_passphrase_ciphertext() {
  if [[ ! -s "$PASSPHRASE_PLAINTEXT" ]]; then
    INSTANCE_ID="$(TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 10") && \
                                curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)"
    METADATA_LOG_FILE="$LUKS_LOG_DIR/passphrase_decryption_md-$(date +"%F-%T").json"
    # Decrypt the ciphertext passphrase
    if ! /usr/local/bin/aws-encryption-cli \
           --decrypt \
           --input "$PASSPHRASE_CIPHERTEXT" \
           --output "$PASSPHRASE_PLAINTEXT" \
           --wrapping-keys provider=aws-kms key="$(cat "$ENCRYPTION_KEY_FILE")" \
           --metadata-output "$METADATA_LOG_FILE" \
           --encryption-context INSTANCE_ID="$INSTANCE_ID"; then
      echo "Failed to decrypt the plaintext ciphertext... Exiting LUKS volume reopen script with failed exit code!"
      exit 2
    fi
    chmod 600 "$PASSPHRASE_PLAINTEXT"
    chmod 600 "$METADATA_LOG_FILE"
  fi
}

reopen_luks_volume() {
  if ! cryptsetup status "$LUKS_VOLUME_NAME"; then
    # Reopen the LUKS volume
    if ! cryptsetup open "$LOOP_DEVICE" "$LUKS_VOLUME_NAME" \
             --key-file "$PASSPHRASE_PLAINTEXT" \
             --type luks2 \
             --debug; then
      echo "Failed to reopen the LUKS volume... Exiting LUKS volume reopen script with failed exit code!"
      exit 3
    fi
  fi
}

remount_luks_volume() {
  if ! mountpoint "$MOUNT_POINT"; then
    # Remount the LUKS volume
    mount "$LUKS_MAPPER_DEVICE" "$MOUNT_POINT"
    chmod 755 "$MOUNT_POINT"
  else
    echo "Did not mount the LUKS volume, as the path is already a mount point... Exiting LUKS volume reopen script with failed exit code!"
    exit 4
  fi
}

main() {
  recreate_loop_device
  setup_tmpfs_for_plaintext_passphrase
  decrypt_passphrase_ciphertext
  reopen_luks_volume
  remount_luks_volume
}

main
