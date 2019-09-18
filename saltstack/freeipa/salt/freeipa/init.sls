{% set freeipa_plugin_base_url = 'https://cloudera-service-delivery-cache.s3.amazonaws.com/cdp-hashed-pwd/workloads/' %}
{% set freeipa_plugin_version = '1.0-20190917183838gitccdab5a' %}
{% set freeipa_plugin_rpm_url = freeipa_plugin_base_url
      + 'cdp-hashed-pwd-' + freeipa_plugin_version
      + '.x86_64.rpm' %}

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

net.ipv6.conf.lo.disable_ipv6:
  sysctl.present:
    - value: 0
