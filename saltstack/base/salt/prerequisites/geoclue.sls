{% if pillar['subtype'] != 'Docker' %}
disable_geoclue_service:
  service.masked:
    - name: geoclue
{% endif %}

remove_geoclue:
  pkg.removed:
    - name: geoclue2