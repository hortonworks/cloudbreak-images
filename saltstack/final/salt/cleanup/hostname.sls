{% if grains['virtual_subtype'] != 'Docker' %}
/etc/hostname:
  file.absent
{% endif %}

{% if grains['os_family'] == 'RedHat' and grains['virtual_subtype'] != 'Docker' %}
hostname_remove:
  file.line:
    - name: /etc/sysconfig/network
    - mode: delete
    - content: "HOSTNAME="
{% endif %}
