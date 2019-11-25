{% set os = salt['environ.get']('OS') %}
{% set metering_rmp_repo_url = 'https://cloudera-service-delivery-cache.s3.amazonaws.com/thunderhead-metering-heartbeat-application/clients/'%}
{% set metering_rpm_location = metering_rmp_repo_url + 'thunderhead-metering-heartbeat-application-0.1-SNAPSHOT.x86_64.rpm' %}

{% if grains['init'] == 'systemd' %}
  {% if os.startswith("centos") or os.startswith("redhat") or os == "amazonlinux2" %}
  install_metering_heartbeat_rpm:
    cmd.run:
      - name: "rpm -i {{ metering_rpm_location }}"
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