{% set os = salt['environ.get']('OS') %}
warning_cdp_telemetry_packages_os:
  cmd.run:
    - name: echo "Warning - CDP telemetry related packages are not supported for this OS type ({{ os }})"