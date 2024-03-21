#!/bin/bash

set -ex -o pipefail

: ${SECRET_ENCRYPTION_KEY_SOURCE:? required}

export LUKS_BACKING_FILE_DEFAULT_SIZE="100MiB"

if mountpoint /mnt/luks; then
  echo "Volume already mounted at mount point... Exiting LUKS volume creation!"
  exit
fi

if [[ -e /etc/luks/luks && $(stat -c "%a" /etc/luks/luks | tr -d '\n') == 600 ]]; then
  # Set the backing file to the specified size if it exists
  truncate -s "$LUKS_BACKING_FILE_DEFAULT_SIZE" /etc/luks/luks
else
  # Create the backing file if it doesn't exist
  dd if=/dev/zero of=/etc/luks/luks bs="$LUKS_BACKING_FILE_DEFAULT_SIZE" count=1
  chmod 600 /etc/luks/luks
fi

if ! mountpoint /mnt/luks_passphrase_tmpfs; then
  # Create the tmpfs for the plaintext passphrase
  mount -t tmpfs -o size=1k,mode=700 tmpfs /mnt/luks_passphrase_tmpfs
fi

if [[ -e /mnt/luks_passphrase_tmpfs/passphrase ]]; then
  echo "Plaintext passphrase already exists... Exiting LUKS volume creation with failed exit code!"
  exit 1
else
  aws kms generate-random \
      --number-of-bytes 64 \
      --output text \
      --query Plaintext \
    | base64 --decode \
    1> /mnt/luks_passphrase_tmpfs/passphrase
fi

# Encrypt the plaintext passphrase and store the ciphertext in persistent storage
if ! /usr/local/bin/aws-encryption-cli \
       --encrypt \
       --input /mnt/luks_passphrase_tmpfs/passphrase \
       --output /etc/luks/passphrase_ciphertext \
       --wrapping-keys provider=aws-kms key="$SECRET_ENCRYPTION_KEY_SOURCE" \
       --metadata-output "/var/log/luks/passphrase_encryption_md-$(date +"%F-%T").json" \
       --encryption-context INSTANCE_ID="$(TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 10") && curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)"; then
  echo "Failed to encrypt plaintext passphrase... Exiting LUKS volume creation with failed exit code!"
  exit 2
fi

# Create the loop device
LOOP_DEVICE=$(losetup --find --show /etc/luks/luks)

if [[ $(losetup -j /etc/luks/luks | cut -d ':' -f1 | tr -d '\n') != "$LOOP_DEVICE" ]]; then
  echo "Failed to set up loop device correctly... Exiting LUKS volume creation with failed exit code!"
  exit 3
fi

# Create the LUKS volume
if ! echo "YES" | cryptsetup luksFormat "$LOOP_DEVICE" \
                   --key-file /mnt/luks_passphrase_tmpfs/passphrase \
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

# Open LUKS volume
if ! cryptsetup open "$LOOP_DEVICE" luks \
         --key-file /mnt/luks_passphrase_tmpfs/passphrase \
         --type luks2 \
         --debug; then
  echo "Failed to open the LUKS volume... Exiting LUKS volume creation with failed exit code!"
  exit 5
fi

# Create the file system on the LUKS volume
if ! mkfs.xfs /dev/mapper/luks; then
  echo "Failed to create the file system on the LUKS volume... Exiting LUKS volume creation with failed exit code!"
  exit 6
fi

# Create backup of LUKS volume header
if ! cryptsetup luksHeaderBackup "$LOOP_DEVICE" \
                  --header-backup-file "/etc/luks/backup/luks_header_backup-$(date +"%F-%T")" \
                  --debug; then
  echo "Failed to create backup of the header of the LUKS volume... Without backup, if the header gets corrupted, the entire volume will become undecryptable!"
fi

if ! mountpoint -q /mnt/luks; then
  # Mount the LUKS volume
  mount /dev/mapper/luks /mnt/luks
  chmod 700 /mnt/luks
else
  echo "Failed to mount the LUKS volume, as the path is already a mount point... Exiting LUKS volume creation with failed exit code!"
  exit 7
fi
