salt_bootstrap_target:
{% if grains['os_family'] == 'Debian' %}
  cloud-init
{% else %}
  multi-user
{% endif %}