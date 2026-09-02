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
    - name: dnf repoquery --show-duplicates --disablerepo="*" --enablerepo="cdp-infra-tools-*" --qf "%{name}-%{version}-%{release}.%{arch} \t\t\t %{repoid}"

install_cdp_infra_tools_packages:
  pkg.installed:
    - pkgs:
{% if salt['environ.get']('INCLUDE_CDP_TELEMETRY') == "Yes" %}
  {% if salt['environ.get']('IMAGE_BURNING_TYPE') == 'prewarm' and salt['environ.get']('STACK_VERSION').split('.') | map('int') | list <= '7.3.1'.split('.') | map('int') | list %}
      - cdp-telemetry: 1.3.10_b1
  {% else %}
      - cdp-telemetry: 1.3.16_b2
  {% endif %}
{% endif %}
{% if salt['environ.get']('INCLUDE_FLUENT') == "Yes" %}
  {% if pillar['OS'] != 'redhat9' %}
      - redhat-lsb-core # this will install redhat-lsb-core which is required for fluent (but not on RHEL 9 as it's not available there!)
  {% endif %}
  {% if salt['environ.get']('IMAGE_BURNING_TYPE') == 'prewarm' and salt['environ.get']('STACK_VERSION').split('.') | map('int') | list <= '7.3.1'.split('.') | map('int') | list %}
      - cdp-logging-agent: 1.3.10_b1
  {% else %}
      - cdp-logging-agent: 1.3.12_b1
  {% endif %}
{% endif %}
{% if pillar['OS'] == 'redhat9' %}
      - cdp-request-signer: 1.3.16_b2
{% else %} # Why do we need this override? Do we still need this?
      - cdp-request-signer: 1.3.7_b2
{% endif %}

remove_cdp_infra_tools_repo:
  file.absent:
    - name: /etc/yum.repos.d/cdp-infra-tools.repo