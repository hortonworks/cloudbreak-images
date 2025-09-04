{% set platform = salt['environ.get']('OS_TYPE') %}
{% if salt['environ.get']('ARCHITECTURE') == 'arm64' %}
  {% set platform = platform ~ 'arm64' %}
{% endif %}

# TODO: Get rid of the whole "internal repo file" as soon as the RHEL 9 builds of cdp-infra-tools are on archive
add_cdp_infra_tools_repo:
  file.managed:
    - name: /etc/yum.repos.d/cdp-infra-tools.repo
{% if pillar['OS'] == 'redhat9' %}
    - source: salt://telemetry/yum/cdp-infra-tools-internal.repo.j2
{% else %}
    - source: salt://telemetry/yum/cdp-infra-tools.repo.j2
{% endif %}
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
  {% if pillar['OS'] != 'redhat9' %}
      - redhat-lsb-core # this will install redhat-lsb-core which is required for fluent (but not on RHEL 9 as it's not available there!)
  {% endif %}
      - cdp-logging-agent
{% endif %}

remove_cdp_infra_tools_repo:
  file.absent:
    - name: /etc/yum.repos.d/cdp-infra-tools.repo

# TODO: Why do we need this override? Do we still need this?
{% if salt['environ.get']('CLOUD_PROVIDER') != "AWS_GOV" %}
override_cdp_request_signer:
  cmd.run:
    - name: |
{% if pillar['OS'] == 'redhat8' and salt['environ.get']('ARCHITECTURE') == 'arm64' %}
        dnf -y install https://archive.cloudera.com/cdp-infra-tools/1.3.7/redhat8arm64/yum/cdp_request_signer-1.3.7_b2.rpm
{% elif pillar['OS'] == 'redhat8' %}
        dnf -y install https://archive.cloudera.com/cdp-infra-tools/1.3.7/redhat8/yum/cdp_request_signer-1.3.7_b2.rpm
{% elif pillar['OS'] == 'centos7' %}
        yum -y install https://archive.cloudera.com/cdp-infra-tools/1.3.7/redhat7/yum/cdp_request_signer-1.3.7_b2.rpm
{% else %}
        echo "No override for RHEL 9."
{% endif %}
{% endif %}