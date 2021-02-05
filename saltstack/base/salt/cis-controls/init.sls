#CentOS Disable unused filesystems
#https://jira.cloudera.com/browse/CB-8897

{% if pillar['OS'] == 'centos7' %}

# fat is required
# udf is required for Azure to mount cdrom - See CB-11012
{% set filesystems = ['cramfs', 'freevxfs', 'jffs2', 'hfs', 'hfsplus', 'squashfs'] %}

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
        - name: modprobe -r {{ fs }}
        - onlyif: "lsmod | grep {{ fs }}"
{% endfor %}

#CentOS - Harden SSH Configurations
#https://jira.cloudera.com/browse/CB-8933

sshd_harden_addressX11:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^X11Forwarding.*"
    - repl: "X11Forwarding no"
    - append_if_not_found: True

sshd_harden_addressMaxAuthTries:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^MaxAuthTries.*"
    - repl: "MaxAuthTries 4"
    - append_if_not_found: True

sshd_harden_addressIgnoreRhosts:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^IgnoreRhosts.*"
    - repl: "IgnoreRhosts yes"
    - append_if_not_found: True

sshd_harden_addressHostbasedAuth:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^HostbasedAuthentication.*"
    - repl: "HostbasedAuthentication no"
    - append_if_not_found: True

sshd_harden_addressEmptyPass:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^PermitEmptyPasswords.*"
    - repl: "PermitEmptyPasswords no"
    - append_if_not_found: True

sshd_harden_addressUserEnvPermit:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^PermitUserEnvironment.*"
    - repl: "PermitUserEnvironment no"
    - append_if_not_found: True

sshd_harden_addressLoginGraceTime:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^LoginGraceTime.*"
    - repl: "LoginGraceTime 60"
    - append_if_not_found: True

# Broken in e2e tests - see CB-8933 / CB-10728
#sshd_harden_sshIdealTime:
#  file.replace:
#    - name: /etc/ssh/sshd_config
#    - pattern: "^ClientAliveInterval.*"
#    - repl: "ClientAliveInterval 600 ClientAliveCountMax 0"
#    - append_if_not_found: True

sshd_harden_ssh2:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^Protocol.*"
    - repl: "Protocol 2"
    - append_if_not_found: True

sshd_harden_WarnBanner1:
  file.managed:
    - name: /etc/issue
    - contents: |
        Corporate computer security personnel monitor this system for security purposes to ensure it remains available to all users and to protect information in the system. By accessing this system, you are expressly consenting to these monitoring activities.
        Unauthorized attempts to defeat or circumvent security features, to use the system for other than intended purposes, to deny service to authorized users, to access, obtain, alter, damage, or destroy information, or otherwise to interfere with the system or its operation are prohibited. Evidence of such acts may be disclosed to law enforcement authorities and result in criminal prosecution under the Computer Fraud and Abuse Act of 1986 (Pub. L. 99-474) and the National Information Infrastructure Protection Act of 1996 (Pub. L. 104-294), (18 U.S.C. 1030), or other applicable criminal laws.
        
sshd_harden_WarnBanner2:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^Banner.*"
    - repl: "Banner /etc/issue"
    - append_if_not_found: True

sshd_harden_ApprovedCiphers:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^Ciphers"
    - repl: "Ciphers aes256-ctr,aes192-ctr,aes128-ctr"
    - append_if_not_found: True

sshd_harden_ApprovedMACs:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^MACs"
    - repl: "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com"
    - append_if_not_found: True

sshd_harden_LogLevel:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^LogLevel"
    - repl: "LogLevel INFO"
    - append_if_not_found: True
{% endif %}
