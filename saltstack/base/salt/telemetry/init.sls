{% set platform = salt['environ.get']('OS_TYPE') %}
{% if salt['environ.get']('ARCHITECTURE') == 'arm64' %}
  {% set platform = platform ~ 'arm64' %}
{% endif %}

add_cdp_infra_tools_repo:
  file.managed:
    - name: /etc/yum.repos.d/cdp-infra-tools.repo
    - source: salt://telemetry/yum/cdp-infra-tools.repo.j2
    - template: jinja
    - platform: "{{ platform }}"

list_available_packages_from_cdp_infra_tools_repo:
  cmd.run:
    - name: yum --disablerepo="*" --enablerepo=cdp-infra-tools list available

install_cdp_infra_tools_packages:
  pkg.installed:
    - pkgs:
{% if salt['environ.get']('INCLUDE_CDP_TELEMETRY') == "Yes" %}
      - cdp-telemetry
{% endif %}
{% if salt['environ.get']('INCLUDE_FLUENT') == "Yes" %}
      - redhat-lsb-core # this will install redhat-lsb-core is required for fluent
      - cdp-logging-agent
{% endif %}

remove_cdp_infra_tools_repo:
  file.absent:
    - name: /etc/yum.repos.d/cdp-infra-tools.repo

{% if salt['environ.get']('CLOUD_PROVIDER') != "AWS_GOV" %}
override_cdp_request_signer:
  cmd.run:
    - name: |
{% if pillar['OS'] == 'redhat8' and salt['environ.get']('ARCHITECTURE') == 'arm64' %}
        dnf -y install https://archive.cloudera.com/cdp-infra-tools/1.3.6/redhat8arm64/yum/cdp_request_signer-1.3.6_b2.rpm
{% elif pillar['OS'] == 'redhat8' %}
        dnf -y install https://archive.cloudera.com/cdp-infra-tools/1.3.6/redhat8/yum/cdp_request_signer-1.3.6_b2.rpm
{% else %}
        yum -y install https://archive.cloudera.com/cdp-infra-tools/1.3.6/redhat7/yum/cdp_request_signer-1.3.6_b2.rpm
{% endif %}
{% endif %}