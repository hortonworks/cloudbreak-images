## see more at internal repo: thunderhead/fluent-service-packager
{% set os = salt['environ.get']('OS') %}
{% set cdp_logging_agent_rpm_repo_url = salt['environ.get']('CDP_LOGGING_AGENT_RPM_URL') %}

{% if cdp_logging_agent_rpm_repo_url %}
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
{% endif %}