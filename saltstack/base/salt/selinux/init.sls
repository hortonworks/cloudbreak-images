/etc/selinux/cdp/common/:
  file.recurse:
    - name: /etc/selinux/cdp/common/
    - source: salt://{{ slspath }}/etc/selinux/cdp/common/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja

/etc/selinux/cdp/hostname/:
  file.recurse:
    - name: /etc/selinux/cdp/hostname/
    - source: salt://{{ slspath }}/etc/selinux/cdp/hostname/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja

/etc/selinux/cdp/httpd/:
  file.recurse:
    - name: /etc/selinux/cdp/httpd/
    - source: salt://{{ slspath }}/etc/selinux/cdp/httpd/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja

/etc/selinux/cdp/init/:
  file.recurse:
    - name: /etc/selinux/cdp/init/
    - source: salt://{{ slspath }}/etc/selinux/cdp/init/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja

/etc/selinux/cdp/ipa/:
  file.recurse:
    - name: /etc/selinux/cdp/ipa/
    - source: salt://{{ slspath }}/etc/selinux/cdp/ipa/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja

/etc/selinux/cdp/kerberos/:
  file.recurse:
    - name: /etc/selinux/cdp/kerberos/
    - source: salt://{{ slspath }}/etc/selinux/cdp/kerberos/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja

{%- if pillar['OS'] == 'redhat9' %}
remove_krb5_conf_file_context_rule:
  file.line:
    - name: /etc/selinux/cdp/kerberos/cdp-kerberos.fc
    - match: '/etc/krb5\\\.conf\s+--\s+gen_context\(system_u:object_r:krb5_conf_t,s0\)'
    - mode: delete
{%- endif %}

{%- if salt['environ.get']('CUSTOM_IMAGE_TYPE') != 'freeipa' %}
/etc/selinux/cdp/postgresql/:
  file.recurse:
    - name: /etc/selinux/cdp/postgresql/
    - source: salt://{{ slspath }}/etc/selinux/cdp/postgresql/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja
{%- endif %}

/etc/selinux/cdp/ipaldapagent-python-wrapper.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
    - template: jinja
    - name: /etc/selinux/cdp/ipaldapagent-python-wrapper.sh
    - source: salt://{{ slspath }}/etc/selinux/cdp/ipaldapagent-python-wrapper.sh

/etc/systemd/system/cdp-freeipa-ldapagent.service.d/override.conf:
  file.managed:
    - makedirs: True
    - contents: |
        [Service]
        ExecStart=
        ExecStart=/etc/selinux/cdp/ipaldapagent-python-wrapper.sh /cdp/ipaldapagent/libs/bin/gunicorn -c gunicorn.conf.py
    - mode: 644
    - user: root
    - group: root

reload-systemd:
  cmd.run:
    - name: systemctl daemon-reexec && systemctl daemon-reload

/etc/selinux/cdp/ipaldapagent/cdp-ipaldapagent.fc:
  file.managed:
    - name: /etc/selinux/cdp/ipaldapagent/cdp-ipaldapagent.fc
    - source: salt://{{ slspath }}/etc/selinux/cdp/ipaldapagent/cdp-ipaldapagent.fc
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/ipaldapagent/cdp-ipaldapagent.portcon:
  file.managed:
    - name: /etc/selinux/cdp/ipaldapagent/cdp-ipaldapagent.portcon
    - source: salt://{{ slspath }}/etc/selinux/cdp/ipaldapagent/cdp-ipaldapagent.portcon
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/ipaldapagent/cdp-ipaldapagent.restorecon:
  file.managed:
    - name: /etc/selinux/cdp/ipaldapagent/cdp-ipaldapagent.restorecon
    - source: salt://{{ slspath }}/etc/selinux/cdp/ipaldapagent/cdp-ipaldapagent.restorecon
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/ipaldapagent/cdp-ipaldapagent.te:
  file.managed:
    - name: /etc/selinux/cdp/ipaldapagent/cdp-ipaldapagent.te
    - source: salt://{{ slspath }}/etc/selinux/cdp/ipaldapagent/cdp-ipaldapagent.te
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/salt/:
  file.recurse:
    - name: /etc/selinux/cdp/salt/
    - source: salt://{{ slspath }}/etc/selinux/cdp/salt/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja

/etc/selinux/cdp/salt-bootstrap/:
  file.recurse:
    - name: /etc/selinux/cdp/salt-bootstrap/
    - source: salt://{{ slspath }}/etc/selinux/cdp/salt-bootstrap/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja

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

/etc/selinux/cdp/user-data-helper/cdp-user-data-helper.fc:
  file.managed:
    - name: /etc/selinux/cdp/user-data-helper/cdp-user-data-helper.fc
    - source: salt://{{ slspath }}/etc/selinux/cdp/user-data-helper/cdp-user-data-helper.fc
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/user-data-helper/cdp-user-data-helper.restorecon:
  file.managed:
    - name: /etc/selinux/cdp/user-data-helper/cdp-user-data-helper.restorecon
    - source: salt://{{ slspath }}/etc/selinux/cdp/user-data-helper/cdp-user-data-helper.restorecon
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/user-data-helper/cdp-user-data-helper.te:
  file.managed:
    - name: /etc/selinux/cdp/user-data-helper/cdp-user-data-helper.te
    - source: salt://{{ slspath }}/etc/selinux/cdp/user-data-helper/cdp-user-data-helper.te
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

/var/log/selinux/:
  file.directory:
    - name: /var/log/selinux/
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

{%- set selinux_booleans = {
  'authlogin_nsswitch_use_ldap': True,
  'daemons_dump_core': True,
  'domain_can_mmap_files': True,
  'domain_can_write_kmsg': True,
  'httpd_can_network_connect': True,
  'polyinstantiation_enabled': True
} -%}

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
