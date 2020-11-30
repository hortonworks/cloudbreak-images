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
{% endif %}
