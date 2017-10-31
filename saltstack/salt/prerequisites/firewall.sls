{% if grains['os_family'] == 'RedHat' %}
ensure_service_iptables_disabled:
  service.disabled:
    - name: iptables
{% endif %}