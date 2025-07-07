{% if pillar['OS'] == 'redhat8' or pillar['OS'] == 'redhat9' %}

disable_firewalld_service:
{% if pillar['subtype'] != 'Docker' %}
  service.dead:
    - name: firewalld
    - enable: False
{% else %}
  cmd.run:
    - name: systemctl disable --now firewalld
    - onlyif: systemctl is-enabled firewalld
{% endif %}

{% if pillar['subtype'] != 'Docker' %}

mask_firewalld_service:
  service.masked:
    - name: firewalld

{% endif %}

{% endif %}