{% set include_cdp_telemetry = salt['environ.get']('INCLUDE_CDP_TELEMETRY') %}
{% set include_fluent = salt['environ.get']('INCLUDE_FLUENT') %}
{% set cdp_telemetry_rpm_repo_url = salt['environ.get']('CDP_TELEMETRY_RPM_URL') %}
{% set cdp_logging_agent_rpm_repo_url = salt['environ.get']('CDP_LOGGING_AGENT_RPM_URL') %}
{% set use_telemetry_archive = salt['environ.get']('USE_TELEMETRY_ARCHIVE') %}
{% set archive_base_url = salt['environ.get']('ARCHIVE_BASE_URL') %}
{% set archive_credentials = salt['environ.get']('ARCHIVE_CREDENTIALS') %}

/cdp/telemetry/install-package.sh:
  file.managed:
    - name: /cdp/telemetry/install-package.sh
    - makedirs: True
    - source: salt://{{ slspath }}/scripts/install-package.sh
    - mode: 700

{% if include_cdp_telemetry == "Yes" %}
{% if use_telemetry_archive == "Yes" %}
## regarding cdp-telemetry, see more at internal repo: thunderhead/cdp-telemetry-cli
install_cdp_telemetry_rpm_from_archive:
  cmd.run:
   - name: "/cdp/telemetry/install-package.sh cdp_telemetry {{ archive_base_url }} {{ archive_credentials }} {{ cdp_telemetry_rpm_repo_url }}"
{% elif cdp_telemetry_rpm_repo_url %}
install_cdp_telemetry_rpm:
  cmd.run:
    - name: "rpm -i {{ cdp_telemetry_rpm_repo_url }}"
{% endif %}
{% endif %}

{% if include_fluent == "Yes" %}
# this will install redhat-lsb-core is required for fluent
install_lsb_core_for_fluent:
  cmd.run:
    - name: yum install -y redhat-lsb-core
{% if use_telemetry_archive == "Yes" %}
install_cdp_logging_rpm_from_archive:
  cmd.run:
   - name: "/cdp/telemetry/install-package.sh cdp_logging_agent {{ archive_base_url }} {{ archive_credentials }} {{ cdp_logging_agent_rpm_repo_url }}"
{% elif cdp_logging_agent_rpm_repo_url %}
install_cdp_logging_rpm_from_repo_url:
  cmd.run:
    - name: rpm -i {{ cdp_logging_agent_rpm_repo_url }}
{% endif %}
{% endif %}

{% if use_telemetry_archive == "Yes" %}
install_minifi:
  cmd.run:
    - name: "/cdp/telemetry/install-package.sh cdp_minifi_agent {{ archive_base_url }} {{ archive_credentials }}"
install_cdp_request_signer:
  cmd.run:
    - name: "/cdp/telemetry/install-package.sh cdp_request_signer {{ archive_base_url }} {{ archive_credentials }}"
{% endif %}

