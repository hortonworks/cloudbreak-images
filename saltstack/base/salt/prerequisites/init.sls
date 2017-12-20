include:
  - {{ slspath }}.repository
  - {{ slspath }}.packages
  - {{ slspath }}.sudo
{% set subtype = grains['virtual_subtype'] |default('', true) %}
{% if subtype != 'Docker' %}
  - {{ slspath }}.sysctl
  - {{ slspath }}.disable_ipv6
  - {{ slspath }}.selinux
{% endif %}
  - {{ slspath }}.ssh
  - {{ slspath }}.pip
  - {{ slspath }}.cert-tool
  - {{ slspath }}.dnsmasq
  - {{ slspath }}.user

/usr/bin/:
  file.recurse:
    - source: salt://{{ slspath }}/usr/bin/
    - include_empty: True
    - file_mode: 755

/usr/lib/jvm:
  file.recurse:
    - source: salt://{{ slspath }}/usr/lib/jvm/
    - include_empty: True
