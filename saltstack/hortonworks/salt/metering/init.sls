{% set os = salt['environ.get']('OS') %}
{% set metering_rmp_url = salt['environ.get']('METERING_AGENT_RPM_URL') %}

{% if metering_rmp_url %}
  {% if grains['init'] == 'systemd' %}
    {% if os.startswith("centos") or os.startswith("redhat") or os == "amazonlinux2" %}
      install_metering_heartbeat_rpm:
        cmd.run:
          - name: "rpm -i {{ metering_rmp_url }}"
      {% if os.startswith("redhat8") %}
      selinux_settings_for_confined_metering_process:
        cmd.run:
          - name: "chcon -t default_t -u system_u /opt/metering-heartbeat && semanage fcontext -a -t default_t -s system_u /opt/metering-heartbeat && restorecon -vF /opt/metering-heartbeat"
      {% endif %}
    {% elif os.startswith("ubuntu") or os.startswith("debian") %}
    install_metering_heartbeat_deb:
      cmd.run:
        - name: echo "Warning - Metering client is not supported (yet) for this OS type ({{ os }})"
    {% else %}
    warning_metering_heartbeat_os:
      cmd.run:
        - name: echo "Warning - Metering client is not supported for this OS type ({{ os }})"
    {% endif %}
  {% else %}
    warning_metering_heartbeat_systemd:
      cmd.run:
        - name: echo "Warning - Metering client requires systemd which is not installed"
  {% endif %}
{% endif %}