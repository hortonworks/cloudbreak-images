{% if pillar['OS'] == 'redhat7' or pillar['OS'] == 'redhat8' %}

disable_firewalld_service:
  service.dead:
    - name: firewalld
    - enable: False

{% if pillar['subtype'] != 'Docker' %}

mask_firewalld_service:
  service.masked:
    - name: firewalld

{% endif %}

{% endif %}