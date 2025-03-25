include:
  - {{ slspath }}.haveged
  - {{ slspath }}.kerberos
{% if salt['environ.get']('CLOUD_PROVIDER') != 'AWS_GOV' and salt['environ.get']('OS') != 'centos7' and pillar['subtype'] != 'Docker' %}
  - {{ slspath }}.ad
{% endif %}