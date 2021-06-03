{% set os = salt['environ.get']('OS') %}
{% set cdp_logging_agent_version = '0.2.11' %}
{% set cdp_logging_agent_rpm_location = 'https://cloudera-service-delivery-cache.s3.amazonaws.com/telemetry/cdp-logging-agent/'%}
{% set cdp_logging_agent_rpm_repo_url = cdp_logging_agent_rpm_location + cdp_logging_agent_version + '/cdp_logging_agent-' + cdp_logging_agent_version + '.x86_64.rpm' %}

{% if os.startswith("centos") or os.startswith("redhat") %}
# this will install redhat-lsb-core on freeipa images
install_lsb_core_for_fluent:
  cmd.run:
    - name: yum install -y redhat-lsb-core
install_fluentd_yum:
  cmd.run:
    - name: rpm -i {{ cdp_logging_agent_rpm_repo_url }}
{% else %}
warning_fluentd_os:
  cmd.run:
    - name: echo "Warning - Fluentd install is not supported for this OS type ({{ os }})"
{% endif %}