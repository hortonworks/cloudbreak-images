/etc/hostname:
  file.absent

/var/dhcp-hook.run:
  file.absent

{% if pillar['OS'] == 'amazonlinux2' %}
hostnamectl_reset:
  cmd.run:
    - name: hostnamectl set-hostname ""
{% endif %}

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
