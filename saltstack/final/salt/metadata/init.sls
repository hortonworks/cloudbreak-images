include:
  - {{ slspath }}.generate-package-versions
{% if pillar['subtype'] == 'Docker' %}
  - {{ slspath }}.generate-docker-manifest
{% endif %}
