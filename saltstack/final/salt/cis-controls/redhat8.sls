blacklist_cramfs:
  file.replace:
    - name: /etc/modprobe.d/salt_cis.conf
    - pattern: "^blacklist cramfs"
    - repl: "blacklist cramfs"
    - append_if_not_found: True

# 5.6.2 Ensure system accounts are secured - non login
set-autossh-nologin-shell:
  user.present:
    - name: autossh
    - shell: {{ salt['cmd.run']('which nologin') }}

# 5.1.9 Ensure at is restricted to authorized users
remove_at_deny:
  file.absent:
    - name: /etc/at.deny

create_at_allow:
  file.managed:
    - name: /etc/at.allow
    - mode: 600
    - user: root
    - group: root
    - contents: |
        cloudera-scm
        apache
        mail

# 1.8.5 Ensure automatic mounting of removable media is disabled
dconf_install:
  pkg.installed:
    - pkgs:
        - dconf

disable_automount:
  file.managed:
    - name: /etc/dconf/db/local.d/00-media-automount
    - contents: |
        [org/gnome/desktop/media-handling]
        automount=false
        automount-open=false

dconf_update:
  cmd.run:
    - name: dconf update

# 3.1.4 Ensure wireless interfaces are disabled
disable_wwan:
  cmd.run:
    - name: nmcli radio wwan off

# 5.2.2 Ensure permissions on SSH private host key files are configured
{% if salt['environ.get']('STIG_ENABLED') == 'true' %}
set_permissions_for_etc_ssh:
  cmd.run:
    - name: chmod -v 600 /etc/ssh/*

set_owners_for_etc_ssh:
  cmd.run:
    - name: chown -v root:root /etc/ssh/*
{% else %}
set_permissions_for_private_host_keys:
  cmd.run:
    - name: find /etc/ssh -type f -name 'ssh_host_*_key' -exec chmod 600 {} \;

set_owners_for_private_host_keys:
  cmd.run:
    - name: find /etc/ssh -type f -name 'ssh_host_*_key' -exec chown root:root {} \;
{% endif %}

gpgcheck_pgdg:
  cmd.run:
    - name: sudo sed -i 's|gpgcheck=0|gpgcheck=1|g' /etc/yum.repos.d/pgdg-redhat-all.repo
    - onlyif: "ls /etc/yum.repos.d/pgdg-redhat-all.repo"

# 5.2.4 Ensure SSH access is limited
deny_nobody:
  file.append:
    - name: /etc/ssh/sshd_config
    - text: "DenyUsers nobody"

ignore_system_wide_crypto_policy_for_ssh::
  cmd.run:
    - name: echo "CRYPTO_POLICY=" | sudo tee -a /etc/sysconfig/sshd

create_subpolicy_remove_cbc_cipher_for_ssh:
  file.append:
    - name: /etc/crypto-policies/policies/modules/DISABLE-CBC.pmod
    - text: "ssh_cipher = -AES-128-CBC -AES-256-CBC"

subpolicy_for_disable_sha1_for_ssh:
  cmd.run:
    - name: sudo cp /usr/share/crypto-policies/policies/modules/NO-SHA1.pmod /etc/crypto-policies/policies/modules/

update_crypto_policies:
  cmd.run:
    - name: sudo update-crypto-policies --set DEFAULT:DISABLE-CBC:NO-SHA1

sshd_harden_ApprovedCiphers:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^Ciphers"
    - repl: "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr"
    - append_if_not_found: True

sshd_harden_ApprovedMACs:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^MACs"
    - repl: "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256"
    - append_if_not_found: True

sshd_Exchange_algorithms:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^KexAlgorithms .*"
    - repl: "KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256"
    - append_if_not_found: True

add_cis_control_sh:
  file.managed:
    - name: /opt/provision-scripts/cis_control.sh
    - makedirs: True
    - mode: 755
    - source: salt://cis-controls/scripts/cis_control.sh
    - template: jinja
    - defaults:
{% if salt['environ.get']('IMAGE_BURNING_TYPE') == 'prewarm' and salt['environ.get']('STACK_VERSION').split('.') | map('int') | list <= '7.3.1'.split('.') | map('int') | list %}
        additional_tags: ",mount_option_tmp_noexec"
{% else %}
        additional_tags: ""
{% endif %}

add_hardening_playbooks:
  file.recurse:
    - name: /mnt/tmp/ansible
    - source: salt://cis-controls/playbooks/
    - template: jinja
    - include_empty: True
    - file_mode: 755

execute_cis_control_sh:
  cmd.run:
    - name: /opt/provision-scripts/cis_control.sh
    - env:
      - IMAGE_BASE_NAME: {{ salt['environ.get']('IMAGE_BASE_NAME') }}
      - CLOUD_PROVIDER: {{ salt['environ.get']('CLOUD_PROVIDER') }}
      - STIG_ENABLED: {{ salt['environ.get']('STIG_ENABLED') }}
