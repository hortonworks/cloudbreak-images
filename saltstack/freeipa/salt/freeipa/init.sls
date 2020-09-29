{% set freeipa_plugin_base_url = 'https://cloudera-service-delivery-cache.s3.amazonaws.com/cdp-hashed-pwd/workloads/' %}
{% set freeipa_plugin_version = '1.0-20200319002729gitc964030' %}
{% set freeipa_plugin_rpm_url = freeipa_plugin_base_url
      + 'cdp-hashed-pwd-' + freeipa_plugin_version
      + '.x86_64.rpm' %}

{% set freeipa_healthagent_base_url = 'https://cloudera-service-delivery-cache.s3.amazonaws.com/freeipa-health-agent/packages/' %}
{% set freeipa_healthagent_version = '0.1-20200811155428gitb402599' %}
{% set freeipa_healthagent_rpm_url = freeipa_healthagent_base_url
      + 'freeipa-health-agent-' + freeipa_healthagent_version
      + '.x86_64.rpm' %}

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

install_freeipa_plugin_rpm:
  pkg.installed:
    - sources:
      - cdp-hashed-pwd: {{ freeipa_plugin_rpm_url }}
    - require:
      - freeipa-install

install_freeipa_healthagent_rpm:
  pkg.installed:
    - sources:
      - freeipa-health-agent: {{ freeipa_healthagent_rpm_url }}
    - require:
      - freeipa-install

net.ipv6.conf.lo.disable_ipv6:
  sysctl.present:
    - value: 0
