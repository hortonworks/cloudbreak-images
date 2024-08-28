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
{% if salt['environ.get']('USE_TELEMETRY_ARCHIVE') == "Yes" and salt['environ.get']('CLOUD_PROVIDER') != "AWS_GOV" %}
      - cdp-request-signer
{% endif %}

remove_cdp_infra_tools_repo:
  file.absent:
    - name: /etc/yum.repos.d/cdp-infra-tools.repo
