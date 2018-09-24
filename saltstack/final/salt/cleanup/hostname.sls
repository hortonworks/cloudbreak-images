/etc/hostname:
  file.absent

/var/dhcp-hook.run:
  file.absent


hostname_remove:
  file.line:
    - name: /etc/sysconfig/network
    - mode: delete
    - content: "HOSTNAME="

hosts_clean:
  file.line:
    - name: /etc/hosts
    - mode: delete
    - content: "{{ grains['host'] }}" 

