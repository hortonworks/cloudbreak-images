{% set subtype = grains['virtual_subtype'] |default('', true) %}
{% if subtype != 'Docker' %}
/etc/hostname:
  file.absent
{% endif %}

{% if grains['os_family'] == 'RedHat' and subtype != 'Docker' %}
hostname_remove:
  file.line:
    - name: /etc/sysconfig/network
    - mode: delete
    - content: "HOSTNAME="
{% endif %}
