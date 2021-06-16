## see more at internal repo: thunderhead/cdp-telemetry-cli
{% set os = salt['environ.get']('OS') %}
{% set cdp_telemetry_rpm_repo_url = salt['environ.get']('CDP_TELEMETRY_RPM_URL') %}

{% if cdp_telemetry_rpm_repo_url %}
{% if os.startswith("centos") or os.startswith("redhat") or os == "amazonlinux2" %}
install_cdp_telemetry_rpm:
  cmd.run:
    - name: "rpm -i {{ cdp_telemetry_rpm_repo_url }}"
{% elif os.startswith("ubuntu") or os.startswith("debian") %}
install_cdp_telemetry_deb:
  cmd.run:
    - name: echo "Warning - CDP Telemetry is not supported (yet) for this OS type ({{ os }})"
{% else %}
warning_cdp_telemetry_os:
  cmd.run:
    - name: echo "Warning - CDP Telemetry is not supported for this OS type ({{ os }})"
{% endif %}
{% endif %}