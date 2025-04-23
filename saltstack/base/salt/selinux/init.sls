{%- if salt['environ.get']('CUSTOM_IMAGE_TYPE') != 'freeipa' %}
/etc/selinux/cdp/postgresql/cdp-postgresql.fc:
  file.managed:
    - name: /etc/selinux/cdp/postgresql/cdp-postgresql.fc
    - source: salt://{{ slspath }}/etc/selinux/cdp/postgresql/cdp-postgresql.fc
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/postgresql/cdp-postgresql.restorecon:
  file.managed:
    - name: /etc/selinux/cdp/postgresql/cdp-postgresql.restorecon
    - source: salt://{{ slspath }}/etc/selinux/cdp/postgresql/cdp-postgresql.restorecon
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/postgresql/cdp-postgresql.te:
  file.managed:
    - name: /etc/selinux/cdp/postgresql/cdp-postgresql.te
    - source: salt://{{ slspath }}/etc/selinux/cdp/postgresql/cdp-postgresql.te
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
{% endif %}

/etc/selinux/cdp/hostname/cdp-hostname.te:
  file.managed:
    - name: /etc/selinux/cdp/hostname/cdp-hostname.te
    - source: salt://{{ slspath }}/etc/selinux/cdp/hostname/cdp-hostname.te
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/salt/cdp-salt.fc:
  file.managed:
    - name: /etc/selinux/cdp/salt/cdp-salt.fc
    - source: salt://{{ slspath }}/etc/selinux/cdp/salt/cdp-salt.fc
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - template: jinja

/etc/selinux/cdp/salt/cdp-salt.restorecon:
  file.managed:
    - name: /etc/selinux/cdp/salt/cdp-salt.restorecon
    - source: salt://{{ slspath }}/etc/selinux/cdp/salt/cdp-salt.restorecon
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - template: jinja

/etc/selinux/cdp/salt/cdp-salt.te:
  file.managed:
    - name: /etc/selinux/cdp/salt/cdp-salt.te
    - source: salt://{{ slspath }}/etc/selinux/cdp/salt/cdp-salt.te
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - template: jinja

/var/log/selinux:
  file.directory:
    - name: /var/log/selinux
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

/etc/selinux/cdp/install-cdp-policies.sh:
  file.managed:
    - name: /etc/selinux/cdp/install-cdp-policies.sh
    - source: salt://{{ slspath }}/etc/selinux/cdp/install-cdp-policies.sh
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

daemons_enable_cluster_mode:
  selinux.boolean:
    - name: daemons_enable_cluster_mode
    - value: True
    - persist: True

domain_can_mmap_files:
  selinux.boolean:
    - name: domain_can_mmap_files
    - value: True
    - persist: True

polyinstantiation_enabled:
  selinux.boolean:
    - name: polyinstantiation_enabled
    - value: True
    - persist: True

run_install-cdp-policies.sh:
  cmd.run:
    - name: /etc/selinux/cdp/install-cdp-policies.sh 2>&1 | tee /var/log/selinux/install-cdp-policies-allout.log && exit ${PIPESTATUS[0]}
    - require:
      - file: /etc/selinux/cdp/install-cdp-policies.sh

/etc/selinux/cdp/httpd_cert_policy.te:
  file.managed:
    - name: /etc/selinux/cdp/httpd_cert_policy.te
    - source: salt://{{ slspath }}/etc/selinux/cdp/httpd_cert_policy.te
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/install-httpd-cert-policy.sh:
  file.managed:
    - name: /etc/selinux/cdp/install-httpd-cert-policy.sh
    - source: salt://{{ slspath }}/etc/selinux/cdp/install-httpd-cert-policy.sh
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

run_install_httpd_cert_policy.sh:
  cmd.run:
    - name: /etc/selinux/cdp/install-httpd-cert-policy.sh
    - require:
      - file: /etc/selinux/cdp/httpd_cert_policy.te
      - file: /etc/selinux/cdp/install-httpd-cert-policy.sh