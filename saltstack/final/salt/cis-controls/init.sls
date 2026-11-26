include:
  - {{ slspath }}.common
{% if pillar['OS'] == 'redhat9' %}
  - {{ slspath }}.redhat9
{% elif pillar['OS'] == 'redhat8' %}
  - {{ slspath }}.redhat8
{% endif %}
  - {{ slspath }}.verify
