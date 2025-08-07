include:
  - {{ slspath }}.common
{% if pillar['OS'] == 'redhat9' %}
  - {{ slspath }}.redhat9
{% elif pillar['OS'] == 'redhat8' %}
  - {{ slspath }}.redhat8
{% elif pillar['OS'] == 'centos7' %}
  - {{ slspath }}.centos7
{% endif %}
  - {{ slspath }}.verify
