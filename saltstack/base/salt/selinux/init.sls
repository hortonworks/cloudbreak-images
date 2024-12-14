/etc/selinux/cdp/hostname_policy.te:
  file.managed:
    - name: /etc/selinux/cdp/hostname_policy.te
    - source: salt://{{ slspath }}/etc/selinux/cdp/hostname_policy.te
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/install-hostname-policy.sh:
  file.managed:
    - name: /etc/selinux/cdp/install-hostname-policy.sh
    - source: salt://{{ slspath }}/etc/selinux/cdp/install-hostname-policy.sh
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

run_install_hostname_policy.sh:
  cmd.run:
    - name: /etc/selinux/cdp/install-hostname-policy.sh
    - require:
      - file: /etc/selinux/cdp/hostname_policy.te
      - file: /etc/selinux/cdp/install-hostname-policy.sh
