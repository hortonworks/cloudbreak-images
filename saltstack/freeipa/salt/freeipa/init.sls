{% set freeipa_plugin_rpm_url = salt['environ.get']('FREEIPA_PLUGIN_RPM_URL') %}
{% set freeipa_healthagent_rpm_url = salt['environ.get']('FREEIPA_HEALTH_AGENT_RPM_URL') %}
{% set freeipa_ldapagent_rpm_url = salt['environ.get']('FREEIPA_LDAP_AGENT_RPM_URL') %}

disable_postfix:
  service.disabled:
    - name: postfix

disable_postgres:
  service.disabled:
    - name: postgresql


freeipa-install:
{% if pillar['OS'] != 'redhat8' %}  
  pkg.installed:
    - pkgs:
        - ntp
        - ipa-server
        - ipa-server-dns
        - python36-dbus
{% else %}
  cmd.run:
    - name: yum module -y reset idm && yum -y install @idm:DL1 && yum -y install freeipa-server && yum -y install ipa-server-dns bind-dyndb-ldap

ipa-healthcheck-install:
  pkg.installed:
    - pkgs:
        - ipa-healthcheck-core: 0.12-4.module+el8.10.0+22138+e77d88cf
        - ipa-healthcheck: 0.12-4.module+el8.10.0+22138+e77d88cf
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
{% endif %}

{% if freeipa_ldapagent_rpm_url %}
install_freeipa_ldapagent_rpm:
  pkg.installed:
    - sources:
      - freeipa-ldap-agent: {{ freeipa_ldapagent_rpm_url }}
    - skip_verify: True
    - require:
      - freeipa-install
{% endif %}

net.ipv6.conf.lo.disable_ipv6:
  sysctl.present:
    - value: 0
