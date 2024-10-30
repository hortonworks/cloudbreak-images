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
export LUKS_BACKUP_DIR="$LUKS_DIR/backup"
export LUKS_MAPPER_DEVICE="/dev/mapper/$LUKS_VOLUME_NAME"
export ENCRYPTION_KEY_FILE="$LUKS_DIR/passphrase_encryption_key"
export LUKS_BACKING_FILE_DEFAULT_SIZE="100MiB"

export AWS_USE_FIPS_ENDPOINT=true
export AWS_RETRY_MODE=standard
export AWS_MAX_ATTEMPTS=15

setup_backing_file() {
  if [[ -e "$LUKS_BACKING_FILE" && $(stat -c "%a" "$LUKS_BACKING_FILE" | tr -d '\n') == 600 ]]; then
    # Set the backing file to the specified size if it exists
    truncate -s "$LUKS_BACKING_FILE_DEFAULT_SIZE" "$LUKS_BACKING_FILE"
  else
    # Create the backing file if it doesn't exist
    dd if=/dev/zero of="$LUKS_BACKING_FILE" bs="$LUKS_BACKING_FILE_DEFAULT_SIZE" count=1
    chmod 600 "$LUKS_BACKING_FILE"
  fi
}

setup_tmpfs_for_plaintext_passphrase() {
  if ! mountpoint "$PASSPHRASE_TMPFS"; then
    # Create the tmpfs for the plaintext passphrase
    mount -t tmpfs -o size="$PASSPHRASE_TMPFS_SIZE",mode=700 tmpfs "$PASSPHRASE_TMPFS"
  fi
}

generate_passphrase() {
  if [[ -e "$PASSPHRASE_PLAINTEXT" ]]; then
    echo "Plaintext passphrase already exists... Exiting LUKS volume creation with failed exit code!"
    exit 1
  else
    aws kms generate-random \
        --number-of-bytes 64 \
        --output text \
        --query Plaintext \
      | base64 --decode \
      > "$PASSPHRASE_PLAINTEXT"
      chmod 600 "$PASSPHRASE_PLAINTEXT"
  fi
}

encrypt_passphrase_ciphertext() {
  INSTANCE_ID="$(TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 10") && \
                                  curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)"
  METADATA_LOG_FILE="$LUKS_LOG_DIR/passphrase_encryption_md-$(date +"%F-%T").json"
  # Encrypt the plaintext passphrase and store the ciphertext
  if ! /usr/local/bin/aws-encryption-cli \
         --encrypt \
         --input "$PASSPHRASE_PLAINTEXT" \
         --output "$PASSPHRASE_CIPHERTEXT" \
         --wrapping-keys provider=aws-kms key="$(cat "$ENCRYPTION_KEY_FILE")" \
         --metadata-output "$METADATA_LOG_FILE" \
         --encryption-context INSTANCE_ID="$INSTANCE_ID"; then
    echo "Failed to encrypt plaintext passphrase... Exiting LUKS volume creation with failed exit code!"
    exit 2
  fi
  chmod 600 "$PASSPHRASE_CIPHERTEXT"
  chmod 600 "$METADATA_LOG_FILE"
}

setup_loop_device() {
  # Create the loop device
  LOOP_DEVICE=$(losetup --find --show "$LUKS_BACKING_FILE")
  if [[ $(losetup -j "$LUKS_BACKING_FILE" | cut -d ':' -f1 | tr -d '\n') != "$LOOP_DEVICE" ]]; then
    echo "Failed to set up the loop device correctly... Exiting LUKS volume creation with failed exit code!"
    exit 3
  fi
}

create_luks_volume() {
  # Create the LUKS volume
  if ! echo "YES" | cryptsetup luksFormat "$LOOP_DEVICE" \
                     --key-file "$PASSPHRASE_PLAINTEXT" \
                     --type luks2 \
                     --hash "sha3-512" \
                     --cipher "aes-xts-plain64" \
                     --use-random \
                     --iter-time 2000 \
                     --pbkdf "pbkdf2" \
                     --debug; then
    echo "Failed to create the LUKS volume... Exiting LUKS volume creation with failed exit code!"
    exit 4
  fi
}

open_luks_volume() {
  # Open the LUKS volume
  if ! cryptsetup open "$LOOP_DEVICE" "$LUKS_VOLUME_NAME" \
           --key-file "$PASSPHRASE_PLAINTEXT" \
           --type luks2 \
           --debug; then
    echo "Failed to open the LUKS volume... Exiting LUKS volume creation with failed exit code!"
    exit 5
  fi
}

create_fs_on_luks_volume() {
  # Create the file system on the LUKS volume
  if ! mkfs.xfs "$LUKS_MAPPER_DEVICE"; then
    echo "Failed to create the file system on the LUKS volume... Exiting LUKS volume creation with failed exit code!"
    exit 6
  fi
}

backup_luks_header() {
  # Create backup of LUKS volume header
  if ! cryptsetup luksHeaderBackup "$LOOP_DEVICE" \
                    --header-backup-file "$LUKS_BACKUP_DIR/luks_header_backup-$(date +"%F-%T")" \
                    --debug; then
    echo "Failed to create backup of the header of the LUKS volume... Without backup, if the header gets corrupted, the entire volume will become undecryptable!"
  fi
}

mount_luks_volume() {
  if ! mountpoint -q "$MOUNT_POINT"; then
    # Mount the LUKS volume
    mount "$LUKS_MAPPER_DEVICE" "$MOUNT_POINT"
    chmod 755 "$MOUNT_POINT"
  else
    echo "Failed to mount the LUKS volume, as the path is already a mount point... Exiting LUKS volume creation with failed exit code!"
    exit 7
  fi
}

main() {
  if mountpoint "$MOUNT_POINT"; then
    echo "Volume already mounted at mount point... Exiting LUKS volume creation!"
    exit
  fi

  setup_backing_file
  setup_tmpfs_for_plaintext_passphrase
  generate_passphrase
  encrypt_passphrase_ciphertext
  setup_loop_device
  create_luks_volume
  open_luks_volume
  create_fs_on_luks_volume
  backup_luks_header
  mount_luks_volume

  # If everything went fine up to this point, we can enable the reopen service,
  # the guards in the unit file will stop it from actually executing the reopen script
  systemctl enable cdp-reopen-luks-volume.service
}

main
