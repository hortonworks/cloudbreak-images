/etc/luks:
  file.directory:
    - name: /etc/luks
    - user: root
    - group: root
    - mode: 700

/etc/luks/bin:
  file.directory:
    - name: /etc/luks/bin
    - user: root
    - group: root
    - mode: 700

/etc/luks/backup:
  file.directory:
    - name: /etc/luks/backup
    - user: root
    - group: root
    - mode: 700

luks_backing_file:
  file.managed:
    - name: /etc/luks/luks
    - user: root
    - group: root
    - mode: 600
    - create: true

passphrase_ciphertext_file:
  file.managed:
    - name: /etc/luks/passphrase_ciphertext
    - user: root
    - group: root
    - mode: 600
    - create: true

passphrase_encryption_key_file:
  file.managed:
    - name: /etc/luks/passphrase_encryption_key
    - user: root
    - group: root
    - mode: 600
    - create: true

luks_mount_point:
  file.directory:
    - name: /mnt/luks
    - user: root
    - group: root
    - mode: 700

luks_passphrase_tmpfs_mount_point:
  file.directory:
    - name: /mnt/luks_passphrase_tmpfs
    - user: root
    - group: root
    - mode: 700

aws_encryption_sdk_logs:
  file.directory:
    - name: /var/log/luks
    - user: root
    - group: root
    - mode: 700

luks_create_script:
  file.managed:
    - name: /etc/luks/bin/create-luks-volume.sh
    - source: salt://{{ slspath }}/bin/create-luks-volume.sh
    - user: root
    - group: root
    - mode: 700

luks_reopen_script:
  file.managed:
    - name: /etc/luks/bin/reopen-luks-volume.sh
    - source: salt://{{ slspath }}/bin/reopen-luks-volume.sh
    - user: root
    - group: root
    - mode: 700

luks_reopen_service:
  file.managed:
    - name: /etc/systemd/system/reopen-luks-volume.service
    - user: root
    - group: root
    - makedirs: True
    - source: salt://{{ slspath }}/etc/systemd/system/reopen-luks-volume.service

enable_luks-reopen_service:
  cmd.run:
    - name: systemctl enable reopen-luks-volume.service

install_aws_encryption_sdk_cli:
  pip.installed:
    - name: aws-encryption-sdk-cli
    - bin_env: /usr/local/bin/pip3.8
