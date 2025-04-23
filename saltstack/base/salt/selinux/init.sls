{%- set selinux_booleans = {
  'authlogin_nsswitch_use_ldap': True,
  'daemons_dump_core': True,
  'domain_can_mmap_files': True,
  'domain_can_write_kmsg': True,
  'httpd_can_network_connect': True,
  'polyinstantiation_enabled': True
} -%}

/etc/selinux/cdp/common/cdp-common.if:
  file.managed:
    - name: /etc/selinux/cdp/common/cdp-common.if
    - source: salt://{{ slspath }}/etc/selinux/cdp/common/cdp-common.if
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - template: jinja

/etc/selinux/cdp/common/cdp-common.te:
  file.managed:
    - name: /etc/selinux/cdp/common/cdp-common.te
    - source: salt://{{ slspath }}/etc/selinux/cdp/common/cdp-common.te
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - template: jinja

/etc/selinux/cdp/hostname/cdp-hostname.te:
  file.managed:
    - name: /etc/selinux/cdp/hostname/cdp-hostname.te
    - source: salt://{{ slspath }}/etc/selinux/cdp/hostname/cdp-hostname.te
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/httpd/cdp-httpd.fc:
  file.managed:
    - name: /etc/selinux/cdp/httpd/cdp-httpd.fc
    - source: salt://{{ slspath }}/etc/selinux/cdp/httpd/cdp-httpd.fc
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - template: jinja

/etc/selinux/cdp/httpd/cdp-httpd.portcon:
  file.managed:
    - name: /etc/selinux/cdp/httpd/cdp-httpd.portcon
    - source: salt://{{ slspath }}/etc/selinux/cdp/httpd/cdp-httpd.portcon
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - template: jinja

/etc/selinux/cdp/httpd/cdp-httpd.restorecon:
  file.managed:
    - name: /etc/selinux/cdp/httpd/cdp-httpd.restorecon
    - source: salt://{{ slspath }}/etc/selinux/cdp/httpd/cdp-httpd.restorecon
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - template: jinja

/etc/selinux/cdp/httpd/cdp-httpd.te:
  file.managed:
    - name: /etc/selinux/cdp/httpd/cdp-httpd.te
    - source: salt://{{ slspath }}/etc/selinux/cdp/httpd/cdp-httpd.te
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - template: jinja

/etc/selinux/cdp/init/cdp-init.te:
  file.managed:
    - name: /etc/selinux/cdp/init/cdp-init.te
    - source: salt://{{ slspath }}/etc/selinux/cdp/init/cdp-init.te
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - template: jinja

/etc/selinux/cdp/ipa/cdp-ipa.fc:
  file.managed:
    - name: /etc/selinux/cdp/ipa/cdp-ipa.fc
    - source: salt://{{ slspath }}/etc/selinux/cdp/ipa/cdp-ipa.fc
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - template: jinja

/etc/selinux/cdp/ipa/cdp-ipa.if:
  file.managed:
    - name: /etc/selinux/cdp/ipa/cdp-ipa.if
    - source: salt://{{ slspath }}/etc/selinux/cdp/ipa/cdp-ipa.if
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - template: jinja

/etc/selinux/cdp/ipa/cdp-ipa.restorecon:
  file.managed:
    - name: /etc/selinux/cdp/ipa/cdp-ipa.restorecon
    - source: salt://{{ slspath }}/etc/selinux/cdp/ipa/cdp-ipa.restorecon
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - template: jinja

/etc/selinux/cdp/ipa/cdp-ipa.te:
  file.managed:
    - name: /etc/selinux/cdp/ipa/cdp-ipa.te
    - source: salt://{{ slspath }}/etc/selinux/cdp/ipa/cdp-ipa.te
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - template: jinja

/etc/selinux/cdp/kerberos/cdp-kerberos.fc:
  file.managed:
    - name: /etc/selinux/cdp/kerberos/cdp-kerberos.fc
    - source: salt://{{ slspath }}/etc/selinux/cdp/kerberos/cdp-kerberos.fc
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - template: jinja

/etc/selinux/cdp/kerberos/cdp-kerberos.restorecon:
  file.managed:
    - name: /etc/selinux/cdp/kerberos/cdp-kerberos.restorecon
    - source: salt://{{ slspath }}/etc/selinux/cdp/kerberos/cdp-kerberos.restorecon
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - template: jinja

/etc/selinux/cdp/kerberos/cdp-kerberos.te:
  file.managed:
    - name: /etc/selinux/cdp/kerberos/cdp-kerberos.te
    - source: salt://{{ slspath }}/etc/selinux/cdp/kerberos/cdp-kerberos.te
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - template: jinja

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
{%- endif %}

/etc/selinux/cdp/salt/cdp-salt.fc:
  file.managed:
    - name: /etc/selinux/cdp/salt/cdp-salt.fc
    - source: salt://{{ slspath }}/etc/selinux/cdp/salt/cdp-salt.fc
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - template: jinja

/etc/selinux/cdp/salt/cdp-salt.if:
  file.managed:
    - name: /etc/selinux/cdp/salt/cdp-salt.if
    - source: salt://{{ slspath }}/etc/selinux/cdp/salt/cdp-salt.if
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - template: jinja

/etc/selinux/cdp/salt/cdp-salt.portcon:
  file.managed:
    - name: /etc/selinux/cdp/salt/cdp-salt.portcon
    - source: salt://{{ slspath }}/etc/selinux/cdp/salt/cdp-salt.portcon
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

/etc/selinux/cdp/salt-bootstrap/cdp-salt-bootstrap.fc:
  file.managed:
    - name: /etc/selinux/cdp/salt-bootstrap/cdp-salt-bootstrap.fc
    - source: salt://{{ slspath }}/etc/selinux/cdp/salt-bootstrap/cdp-salt-bootstrap.fc
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/salt-bootstrap/cdp-salt-bootstrap.portcon:
  file.managed:
    - name: /etc/selinux/cdp/salt-bootstrap/cdp-salt-bootstrap.portcon
    - source: salt://{{ slspath }}/etc/selinux/cdp/salt-bootstrap/cdp-salt-bootstrap.portcon
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/salt-bootstrap/cdp-salt-bootstrap.restorecon:
  file.managed:
    - name: /etc/selinux/cdp/salt-bootstrap/cdp-salt-bootstrap.restorecon
    - source: salt://{{ slspath }}/etc/selinux/cdp/salt-bootstrap/cdp-salt-bootstrap.restorecon
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/salt-bootstrap/cdp-salt-bootstrap.te:
  file.managed:
    - name: /etc/selinux/cdp/salt-bootstrap/cdp-salt-bootstrap.te
    - source: salt://{{ slspath }}/etc/selinux/cdp/salt-bootstrap/cdp-salt-bootstrap.te
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/cdp-policy-installer.fc:
  file.managed:
    - name: /etc/selinux/cdp/cdp-policy-installer.fc
    - source: salt://{{ slspath }}/etc/selinux/cdp/cdp-policy-installer.fc
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/cdp-policy-installer.restorecon:
  file.managed:
    - name: /etc/selinux/cdp/cdp-policy-installer.restorecon
    - source: salt://{{ slspath }}/etc/selinux/cdp/cdp-policy-installer.restorecon
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/cdp-policy-installer.te:
  file.managed:
    - name: /etc/selinux/cdp/cdp-policy-installer.te
    - source: salt://{{ slspath }}/etc/selinux/cdp/cdp-policy-installer.te
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/install-cdp-policies.sh:
  file.managed:
    - name: /etc/selinux/cdp/install-cdp-policies.sh
    - source: salt://{{ slspath }}/etc/selinux/cdp/install-cdp-policies.sh
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

/etc/selinux/cdp/install-policy-installer-policy.sh:
  file.managed:
    - name: /etc/selinux/cdp/install-policy-installer-policy.sh
    - source: salt://{{ slspath }}/etc/selinux/cdp/install-policy-installer-policy.sh
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

/etc/selinux/cdp/policy-install-utils.sh:
  file.managed:
    - name: /etc/selinux/cdp/policy-install-utils.sh
    - source: salt://{{ slspath }}/etc/selinux/cdp/policy-install-utils.sh
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

/var/log/selinux:
  file.directory:
    - name: /var/log/selinux
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

run_install-policy-installer-policy.sh:
  cmd.run:
    - name: /etc/selinux/cdp/install-policy-installer-policy.sh 2>&1 | tee /var/log/selinux/cdp-policy-installer-allout.log && exit ${PIPESTATUS[0]}
    - require:
      - file: /etc/selinux/cdp/cdp-policy-installer.te
      - file: /etc/selinux/cdp/cdp-policy-installer.fc
      - file: /etc/selinux/cdp/cdp-policy-installer.restorecon
      - file: /etc/selinux/cdp/install-policy-installer-policy.sh
      - file: /etc/selinux/cdp/policy-install-utils.sh

{%- for boolean, value in selinux_booleans.items() %}
{{ boolean }}:
  selinux.boolean:
    - name: {{ boolean }}
    - value: {{ value }}
    - persist: True
{%- endfor %}

run_install-cdp-policies.sh:
  cmd.run:
    - name: /etc/selinux/cdp/install-cdp-policies.sh 2>&1 | tee /var/log/selinux/install-cdp-policies-allout.log && exit ${PIPESTATUS[0]}
    - require:
      - file: /etc/selinux/cdp/install-cdp-policies.sh
      - file: /etc/selinux/cdp/policy-install-utils.sh

## Useful SELinux policy development. Uncomment if needed.
#disable_dontaudit_rules:
#  cmd.run:
#    - name: semodule -DB
#    - runas: root
