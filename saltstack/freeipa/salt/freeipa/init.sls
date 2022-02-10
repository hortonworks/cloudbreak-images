{% set freeipa_plugin_rpm_url = salt['environ.get']('FREEIPA_PLUGIN_RPM_URL') %}
{% set freeipa_healthagent_rpm_url = salt['environ.get']('FREEIPA_HEALTH_AGENT_RPM_URL') %}

disable_postfix:
  service.disabled:
    - name: postfix

disable_postgres:
  service.disabled:
    - name: postgresql

freeipa-install:
  pkg.installed:
    - pkgs:
        - ntp
        - ipa-server
        - ipa-server-dns

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
install_freeipa_healthagent_rpm:
  pkg.installed:
    - sources:
      - freeipa-health-agent: {{ freeipa_healthagent_rpm_url }}
    - skip_verify: True
    - require:
      - freeipa-install
{% endif %}

net.ipv6.conf.lo.disable_ipv6:
  sysctl.present:
    - value: 0

/usr/lib/python2.7/site-packages/ipaserver/plugins/stageuser.py:
  file.patch:
    - source: salt://{{ slspath }}/tmp/stageuser.py.patch
    - hash: md5=c34ee2a14a0480f07faef36507626bc6
    - require:
      - freeipa-install

/usr/lib/python2.7/site-packages/ipaserver/plugins/user.py:
  file.patch:
    - source: salt://{{ slspath }}/tmp/user.py.patch
    - hash: md5=47508b761dfe42f173eee53a90bfb4db
    - require:
      - freeipa-install
