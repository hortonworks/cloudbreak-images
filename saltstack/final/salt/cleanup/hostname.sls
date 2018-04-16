/etc/hostname:
  file.absent

{% if grains['os_family'] == 'RedHat' %}
hostname_remove:
  file.line:
    - name: /etc/sysconfig/network
    - mode: delete
    - content: "HOSTNAME="
{% elif grains['os_family'] == 'Suse' %}
hostname_remove:
  file.line:
    - name: /etc/sysconfig/network/config
    - mode: delete
    - content: "HOSTNAME="

hosts_clean:
  file.line:
    - name: /etc/hosts
    - mode: delete
    - content: "{{ grains['host'] }}" 
{% endif %}
