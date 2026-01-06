/etc/selinux/cdp/blackbox-exporter/:
  file.recurse:
    - name: /etc/selinux/cdp/blackbox-exporter/
    - source: salt://{{ slspath }}/etc/selinux/cdp/blackbox-exporter/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja

/etc/selinux/cdp/common/:
  file.recurse:
    - name: /etc/selinux/cdp/common/
    - source: salt://{{ slspath }}/etc/selinux/cdp/common/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja

/etc/selinux/cdp/crontab/:
  file.recurse:
    - name: /etc/selinux/cdp/crontab/
    - source: salt://{{ slspath }}/etc/selinux/cdp/crontab/
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

/etc/selinux/cdp/ipahealthagent:
  file.recurse:
    - name: /etc/selinux/cdp/ipahealthagent/
    - source: salt://{{ slspath }}/etc/selinux/cdp/ipahealthagent/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True

/etc/selinux/cdp/ipaldapagent:
  file.recurse:
    - name: /etc/selinux/cdp/ipaldapagent/
    - source: salt://{{ slspath }}/etc/selinux/cdp/ipaldapagent/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True

/etc/selinux/cdp/jumpgate-agent/:
  file.recurse:
    - name: /etc/selinux/cdp/jumpgate-agent/
    - source: salt://{{ slspath }}/etc/selinux/cdp/jumpgate-agent/
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

/etc/selinux/cdp/logging-agent/:
  file.recurse:
    - name: /etc/selinux/cdp/logging-agent/
    - source: salt://{{ slspath }}/etc/selinux/cdp/logging-agent/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja

/etc/selinux/cdp/node-exporter/:
  file.recurse:
    - name: /etc/selinux/cdp/node-exporter/
    - source: salt://{{ slspath }}/etc/selinux/cdp/node-exporter/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja

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

/etc/selinux/cdp/prometheus/:
  file.recurse:
    - name: /etc/selinux/cdp/prometheus/
    - source: salt://{{ slspath }}/etc/selinux/cdp/prometheus/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja

/etc/selinux/cdp/recipes/:
  file.recurse:
    - name: /etc/selinux/cdp/recipes/
    - source: salt://{{ slspath }}/etc/selinux/cdp/recipes/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja

/etc/selinux/cdp/request-signer/:
  file.recurse:
    - name: /etc/selinux/cdp/request-signer/
    - source: salt://{{ slspath }}/etc/selinux/cdp/request-signer/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja

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

/etc/selinux/cdp/user-data-helper/:
  file.recurse:
    - name: /etc/selinux/cdp/user-data-helper/
    - source: salt://{{ slspath }}/etc/selinux/cdp/user-data-helper/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - template: jinja

/etc/selinux/cdp/tomcat/:
  file.recurse:
    - name: /etc/selinux/cdp/tomcat/
    - source: salt://{{ slspath }}/etc/selinux/cdp/tomcat/
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
    - hide_output: True
    - require:
      - file: /etc/selinux/cdp/install-cdp-policies.sh
      - file: /etc/selinux/cdp/policy-install-utils.sh

/tmp/selinux-logs/:
  file.directory:
    - name: /tmp/selinux-logs/
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

collect_selinux_logs:
  cmd.run:
    - name: cp /var/log/selinux/*.log /tmp/selinux-logs/

## Useful SELinux policy development. Uncomment if needed.
#disable_dontaudit_rules:
#  cmd.run:
#    - name: semodule -DB
#    - runas: root
