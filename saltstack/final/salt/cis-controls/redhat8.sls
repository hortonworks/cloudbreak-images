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

add_cis_control_sh:
  file.managed:
    - name: /tmp/cis_control.sh
    - makedirs: True
    - mode: 755
    - source: salt://cis-controls/scripts/cis_control.sh

add_hardening_playbooks:
  file.recurse:
    - name: /mnt/tmp/ansible
    - source: salt://cis-controls/playbooks/
    - template: jinja
    - include_empty: True
    - file_mode: 755

execute_cis_control_sh:
  cmd.run:
    - name: /tmp/cis_control.sh
    - env:
      - IMAGE_BASE_NAME: {{ salt['environ.get']('IMAGE_BASE_NAME') }}
      - CLOUD_PROVIDER: {{ salt['environ.get']('CLOUD_PROVIDER') }}
      - STIG_ENABLED: {{ salt['environ.get']('STIG_ENABLED') }}

remove_cis_control_sh:
  file.absent:
    - name: /tmp/cis_control.sh