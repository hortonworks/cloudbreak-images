{% set freeipa_plugin_rpm_url = salt['environ.get']('FREEIPA_PLUGIN_RPM_URL') %}
{% set freeipa_healthagent_rpm_url = salt['environ.get']('FREEIPA_HEALTH_AGENT_RPM_URL') %}
{% set freeipa_ldapagent_rpm_url = salt['environ.get']('FREEIPA_LDAP_AGENT_RPM_URL') %}

disable_postfix:
  service.disabled:
    - name: postfix

disable_postgres:
  service.disabled:
    - name: postgresql

### Freeipa related packages. PyYAML (CB-18497)
freeipa-prerequisites:
  cmd.run:
    - name: python3 -m pip install 'PyYAML>=5.1' --ignore-installed

freeipa-cipa:
  cmd.run:
    - name: python3 -m virtualenv /opt/cipa_venv && source /opt/cipa_venv/bin/activate && python3 -m pip install 'pyasn1==0.5.1' && python3 -m pip install 'pyasn1-modules==0.3.0' && python3 -m pip install 'checkipaconsistency==2.7.10' && deactivate

freeipa-cipa-venv-wrapper:
  file.managed:
    - name: /usr/bin/cipa
    - mode: 755
    - contents: |
        #!/bin/bash
        source /opt/cipa_venv/bin/activate
        cipa "$@"
        deactivate

freeipa-install:
{% if pillar['OS'] != 'redhat8' and pillar['OS'] != 'redhat9' %}
  pkg.installed:
    - pkgs:
        - ntp
        - ipa-server
        - ipa-server-dns
        - python36-dbus
{% else %}
  cmd.run:
    - name: yum module -y reset idm && yum -y install @idm:DL1 && yum -y install freeipa-server && yum -y install ipa-server-dns bind-dyndb-ldap ipa-server-trust-ad samba-client
{% endif %}

{% if freeipa_plugin_rpm_url %}
install_freeipa_plugin_rpm:
  pkg.installed:
    - sources:
      - cdp-hashed-pwd: {{ freeipa_plugin_rpm_url }}
    - skip_verify: True
    - require:
      - freeipa-install
{% endif %}

{% if freeipa_healthagent_rpm_url %}
inotifytools-install:
  pkg.installed:
    - pkgs:
        - inotify-tools

install_freeipa_healthagent_rpm:
  pkg.installed:
    - sources:
      - freeipa-health-agent: {{ freeipa_healthagent_rpm_url }}
    - skip_verify: True
    - require:
      - freeipa-install

{% set ipahealthagent_python_bin_file = "/tmp/ipahealthagent_python_bin.txt" %}
{% set ipahealthagent_exec_args_file = "/tmp/ipahealthagent_exec_args.txt" %}

ipahealthagent_python_bin_file:
  file.managed:
    - name: /tmp/ipahealthagent_python_bin.txt
    - contents: ""
    - mode: 644
    - user: root
    - group: root
    - makedirs: True
    - require:
      - install_freeipa_healthagent_rpm

ipahealthagent_exec_args_file:
  file.managed:
    - name: /tmp/ipahealthagent_exec_args.txt
    - contents: ""
    - mode: 644
    - user: root
    - group: root
    - makedirs: True
    - require:
      - install_freeipa_healthagent_rpm

parse_python_bin_ipahealthagent_exec_start:
  cmd.run:
    - name: "systemctl show cdp-freeipa-healthagent.service | sed -n 's/.*argv\\[\\]=\\([^ ]* [^ ]*\\) \\/cdp.*/\\1/p' > {{ ipahealthagent_python_bin_file }}"
    - require:
      - install_freeipa_healthagent_rpm
      - ipahealthagent_python_bin_file

parse_exec_args_ipahealthagent_exec_start:
  cmd.run:
    - name: "systemctl show cdp-freeipa-healthagent.service | sed -n 's/.*argv\\[\\]=[^ ]* [^ ]* \\(\\/cdp[^;]*\\) ;.*/\\1/p' > {{ ipahealthagent_exec_args_file }}"
    - require:
      - install_freeipa_healthagent_rpm
      - ipahealthagent_exec_args_file

modify_ipahealthagent_python_wrapper:
  file.managed:
    - name: /etc/selinux/cdp/ipahealthagent-python-wrapper.sh
    - mode: 755
    - user: root
    - group: root
    - makedirs: True
    - template: jinja
    - source: salt://{{ slspath }}/templates/ipahealthagent-python-wrapper.sh.j2
    - context:
        python_bin: {{ salt['file.read'](ipahealthagent_python_bin_file) | trim }}
    - require:
      - parse_python_bin_ipahealthagent_exec_start

override_ipahealthagent_exec_start:
  file.managed:
    - name: /etc/systemd/system/cdp-freeipa-healthagent.override
    - mode: 644
    - user: root
    - group: root
    - makedirs: True
    - template: jinja
    - source: salt://{{ slspath }}/templates/ipahealthagent-override.conf.j2
    - context:
        exec_args: {{ salt['file.read'](ipahealthagent_exec_args_file) | trim }}
    - require:
      - modify_ipahealthagent_python_wrapper
      - parse_exec_args_ipahealthagent_exec_start

reload_ipahealthagent_systemd:
  cmd.run:
    - name: systemctl daemon-reload
    - require:
      - /etc/systemd/system/cdp-freeipa-healthagent.service.d/override.conf
{% endif %}


{% if freeipa_ldapagent_rpm_url %}

install_freeipa_ldapagent_rpm:
  pkg.installed:
    - sources:
      - freeipa-ldap-agent: {{ freeipa_ldapagent_rpm_url }}
    - skip_verify: True
    - require:
      - freeipa-install

{% set ipaldapagent_python_bin_file = "/tmp/ipaldapagent_python_bin.txt" %}
{% set ipaldapagent_exec_args_file = "/tmp/ipaldapagent_exec_args.txt" %}

ipaldapagent_python_bin_file:
  file.managed:
    - name: /tmp/ipaldapagent_python_bin.txt
    - contents: ""
    - mode: 644
    - user: root
    - group: root
    - makedirs: True
    - require:
      - install_freeipa_ldapagent_rpm

ipaldapagent_exec_args_file:
  file.managed:
    - name: /tmp/ipaldapagent_exec_args.txt
    - contents: ""
    - mode: 644
    - user: root
    - group: root
    - makedirs: True
    - require:
      - install_freeipa_ldapagent_rpm

parse_python_bin_ipaldapagent_exec_start:
  cmd.run:
    - name: "systemctl show cdp-freeipa-ldapagent.service | sed -n 's/.*argv\\[\\]=\\([^ ]* [^ ]*\\) \\/cdp.*/\\1/p' > {{ ipaldapagent_python_bin_file }}"
    - require:
      - install_freeipa_ldapagent_rpm
      - ipaldapagent_python_bin_file

parse_exec_args_ipaldapagent_exec_start:
  cmd.run:
    - name: "systemctl show cdp-freeipa-ldapagent.service | sed -n 's/.*argv\\[\\]=[^ ]* [^ ]* \\(\\/cdp[^;]*\\) ;.*/\\1/p' > {{ ipaldapagent_exec_args_file }}"
    - require:
      - install_freeipa_ldapagent_rpm
      - ipaldapagent_exec_args_file

modify_ipaldapagent_python_wrapper:
  file.managed:
    - name: /etc/selinux/cdp/ipaldapagent-python-wrapper.sh
    - mode: 755
    - user: root
    - group: root
    - makedirs: True
    - template: jinja
    - source: salt://{{ slspath }}/templates/ipaldapagent-python-wrapper.sh.j2
    - context:
        python_bin: {{ salt['file.read'](ipaldapagent_python_bin_file) | trim }}
    - require:
      - parse_python_bin_ipaldapagent_exec_start

override_ipaldapagent_exec_start:
  file.managed:
    - name: /etc/systemd/system/cdp-freeipa-ldapagent.override
    - mode: 644
    - user: root
    - group: root
    - makedirs: True
    - template: jinja
    - source: salt://{{ slspath }}/templates/ipaldapagent-override.conf.j2
    - context:
        exec_args: {{ salt['file.read'](ipaldapagent_exec_args_file) | trim }}
    - require:
      - modify_ipaldapagent_python_wrapper
      - parse_exec_args_ipaldapagent_exec_start

reload_ipaldapagent_systemd:
  cmd.run:
    - name: systemctl daemon-reload
    - require:
      - /etc/systemd/system/cdp-freeipa-ldapagent.service.d/override.conf
{% endif %}

net.ipv6.conf.lo.disable_ipv6:
  sysctl.present:
    - value: 0
