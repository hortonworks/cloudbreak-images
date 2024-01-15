{% set os = salt['environ.get']('OS') %}
{% set metering_rmp_url = salt['environ.get']('METERING_AGENT_RPM_URL') %}

{% if metering_rmp_url %}
  {% if grains['init'] == 'systemd' %}
    install_metering_heartbeat_rpm:
      cmd.run:
        - name: "rpm -i {{ metering_rmp_url }}"
  {% else %}
    warning_metering_heartbeat_systemd:
      cmd.run:
        - name: echo "Warning - Metering client requires systemd which is not installed"
  {% endif %}
{% endif %}