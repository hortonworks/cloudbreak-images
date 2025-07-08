{% if salt['environ.get']('CUSTOM_IMAGE_TYPE') != 'freeipa' %}
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

/etc/selinux/cdp/common/cdp-common.te:
  file.managed:
    - name: /etc/selinux/cdp/common/cdp-common.te
    - source: salt://{{ slspath }}/etc/selinux/cdp/common/cdp-common.te
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

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

/etc/selinux/cdp/salt/cdp-salt.restorecon:
  file.managed:
    - name: /etc/selinux/cdp/salt/cdp-salt.restorecon
    - source: salt://{{ slspath }}/etc/selinux/cdp/salt/cdp-salt.restorecon
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/selinux/cdp/salt/cdp-salt.te:
  file.managed:
    - name: /etc/selinux/cdp/salt/cdp-salt.te
    - source: salt://{{ slspath }}/etc/selinux/cdp/salt/cdp-salt.te
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

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

run_install-cdp-policies.sh:
  cmd.run:
    - name: /etc/selinux/cdp/install-cdp-policies.sh 2>&1 | tee /var/log/install-cdp-policies.log && exit ${PIPESTATUS[0]}
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