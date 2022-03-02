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
