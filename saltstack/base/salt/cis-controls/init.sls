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
        - name: modprobe -r {{ fs }} && rmmod {{ fs }}
        - onlyif: "lsmod | grep {{ fs }}"
{% endfor %}

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

{% endif %}
