#CentOS Disable unused filesystems
#https://jira.cloudera.com/browse/CB-8897

{% if pillar['OS'] == 'centos7' %}
{% set filesystems = ['cramfs', 'freevxfs', 'jffs2', 'hfs', 'hfsplus', 'squashfs', 'udf', 'fat'] %}

{% for fs in filesystems %}

{{ fs }} create modrobe blacklist:
    cmd.run:
        - name: touch /etc/modprobe.d/salt_cis.conf
        - unless: test -f /etc/modprobe.d/salt_cis.conf

{{ fs }} disabled:
    file.replace:
        - name: /etc/modprobe.d/salt_cis.conf
        - pattern: "^install {{ fs }} /bin/true"
        - repl: install {{ fs }} /bin/true
        - append_if_not_found: True
    cmd.run:
        - name: modprobe -r {{ fs }} && rmmod {{ fs }} > /dev/null 2>&1
        - onlyif: "lsmod | grep {{ fs }}"
{% endfor %}

#CentOS - Harden SSH Configurations
#https://jira.cloudera.com/browse/CB-8933

sshd_harden_addressX11:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^X11Forwarding"
    - repl: "X11Forwarding no"
    - append_if_not_found: True

sshd_harden_addressMaxAuthTries:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^MaxAuthTries"
    - repl: "MaxAuthTries 4"
    - append_if_not_found: True

sshd_harden_addressIgnoreRhosts:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^IgnoreRhosts"
    - repl: "IgnoreRhosts yes"
    - append_if_not_found: True

sshd_harden_addressHostbasedAuth:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^HostbasedAuthentication"
    - repl: "HostbasedAuthentication no"
    - append_if_not_found: True

sshd_harden_addressEmptyPass:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^PermitEmptyPasswords"
    - repl: "PermitEmptyPasswords no"
    - append_if_not_found: True

sshd_harden_addressUserEnvPermit:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^PermitUserEnvironment"
    - repl: "PermitUserEnvironment no"
    - append_if_not_found: True

sshd_harden_addressLoginGraceTime:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^LoginGraceTime"
    - repl: "LoginGraceTime 60"
    - append_if_not_found: True

sshd_harden_sshIdealTime:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^ClientAliveInterval"
    - repl: "ClientAliveInterval 900 ClientAliveCountMax 0"
    - append_if_not_found: True

sshd_harden_ssh2:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^Protocol"
    - repl: "Protocol 2"
    - append_if_not_found: True

{% endif %}
