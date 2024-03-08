#!/bin/bash

set -ex -o pipefail

if [[ $(losetup -j /etc/luks/luks | wc -l | tr -d '\n') == 0 ]]; then
  # Recreate the loop device
  LOOP_DEVICE=$(losetup --find --show /etc/luks/luks)

  if [[ $(losetup -j /etc/luks/luks | cut -d ':' -f1 | tr -d '\n') != "$LOOP_DEVICE" ]]; then
    echo "Failed to set up loop device correctly... Exiting LUKS volume reopen script with failed exit code!"
    exit 1
  fi
fi

if [[ ! -s /mnt/luks_passphrase_tmpfs/passphrase ]]; then
  # Decrypt the ciphertext passphrase
  install -m 600 /dev/null /mnt/luks_passphrase_tmpfs/passphrase
  if ! /usr/local/bin/aws-encryption-cli \
         --decrypt \
         --input /etc/luks/passphrase_ciphertext \
         --output /mnt/luks_passphrase_tmpfs/passphrase \
         --wrapping-keys provider=aws-kms key="$(cat /etc/luks/passphrase_encryption_key)" \
         --metadata-output "/var/log/luks/passphrase_decryption_md-$(date +"%F-%T").json" \
         --encryption-context INSTANCE_ID="$(TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 10") && curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)"; then
    echo "Failed to decrypt the plaintext ciphertext... Exiting LUKS volume reopen script with failed exit code!"
    exit 2
  fi
fi

if ! cryptsetup status luks; then
  # Reopen the LUKS volume
  if ! cryptsetup open "$LOOP_DEVICE" luks \
           --key-file /mnt/luks_passphrase_tmpfs/passphrase \
           --type luks2 \
           --debug; then
    echo "Failed to reopen the LUKS volume... Exiting LUKS volume reopen script with failed exit code!"
    exit 3
  fi
fi

if ! mountpoint /mnt/luks; then
  # Remount the LUKS volume
  mount /dev/mapper/luks /mnt/luks
  chmod 700 /mnt/luks
else
  echo "Did not mount the LUKS volume, as the path is already a mount point..."
fi
