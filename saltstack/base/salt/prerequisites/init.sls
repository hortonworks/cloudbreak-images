include:
  - {{ slspath }}.packages
{% if pillar['subtype'] != 'Docker' %}
  - {{ slspath }}.selinux
{% endif %}
  - {{ slspath }}.pip
  - {{ slspath }}.cert-tool
  - {{ slspath }}.jinja
  - {{ slspath }}.corkscrew