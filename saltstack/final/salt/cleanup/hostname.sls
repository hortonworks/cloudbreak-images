/etc/hostname:
  file.absent

{% if grains['os_family'] == 'RedHat' %}
hostname_remove:
  file.line:
    - name: /etc/sysconfig/network
    - mode: delete
    - content: "HOSTNAME="
{% endif %}
