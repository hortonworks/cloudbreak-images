/etc/cdp-luks:
  file.directory:
    - name: /etc/cdp-luks
    - user: root
    - group: root
    - mode: 700

/etc/cdp-luks/bin:
  file.directory:
    - name: /etc/cdp-luks/bin
    - user: root
    - group: root
    - mode: 700

/etc/cdp-luks/backup:
  file.directory:
    - name: /etc/cdp-luks/backup
    - user: root
    - group: root
    - mode: 700

/mnt/cdp-luks:
  file.directory:
    - name: /mnt/cdp-luks
    - user: root
    - group: root
    - mode: 700

/mnt/cdp-luks_passphrase_tmpfs:
  file.directory:
    - name: /mnt/cdp-luks_passphrase_tmpfs
    - user: root
    - group: root
    - mode: 700

/var/log/cdp-luks:
  file.directory:
    - name: /var/log/cdp-luks
    - user: root
    - group: root
    - mode: 700

/etc/cdp-luks/bin/create-luks-volume.sh:
  file.managed:
    - name: /etc/cdp-luks/bin/create-luks-volume.sh
    - source: salt://{{ slspath }}/bin/create-luks-volume.sh
    - user: root
    - group: root
    - mode: 700

/etc/cdp-luks/bin/populate-luks-volume.sh:
  file.managed:
    - name: /etc/cdp-luks/bin/populate-luks-volume.sh
    - source: salt://{{ slspath }}/bin/populate-luks-volume.sh
    - user: root
    - group: root
    - mode: 700

/etc/cdp-luks/bin/reopen-luks-volume.sh:
  file.managed:
    - name: /etc/cdp-luks/bin/reopen-luks-volume.sh
    - source: salt://{{ slspath }}/bin/reopen-luks-volume.sh
    - user: root
    - group: root
    - mode: 700

/etc/systemd/system/cdp-reopen-luks-volume.service:
  file.managed:
    - name: /etc/systemd/system/cdp-reopen-luks-volume.service
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - source: salt://{{ slspath }}/etc/systemd/system/cdp-reopen-luks-volume.service

install_aws_encryption_sdk_cli:
  pip.installed:
    - name: aws-encryption-sdk-cli
    - bin_env: /usr/local/bin/pip3.8
