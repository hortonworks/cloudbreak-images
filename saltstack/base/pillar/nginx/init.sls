nginx_user:
{% if grains['os_family'] == 'Debian' %}
  www-data
{% else %}
  nginx
{% endif %}
