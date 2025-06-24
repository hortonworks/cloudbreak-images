{% if salt['environ.get']('CLOUD_PROVIDER') == "AWS" %}
{% if pillar['OS'] == 'centos7' %}
mount-nfs-sequentially-service-file:
  file.managed:
    - user: root
    - group: root
    - name: /etc/systemd/system/mount-nfs-sequentially.service
    - makedirs: True
    - source: salt://{{ slspath }}/etc/systemd/system/mount-nfs-sequentially.service

mount-nfs-sequentially-service-start:
  service.running:
    - name: mount-nfs-sequentially
    - enable: True
    - reload: True
    - require:
      - file: mount-nfs-sequentially-service-file
{% elif pillar['OS'] == 'redhat8' or pillar['OS'] == 'redhat9' %}
format-additional-disk:
  cmd.run:
    - name: mkfs.xfs /dev/nvme1n1

create-additional-disk-mount-point:
  file.directory:
    - name: /mnt/tmp/

mount-additional-disk:
  cmd.run:
    - name: mount /dev/nvme1n1 /mnt/tmp/
{% endif %}
{% elif salt['environ.get']('CLOUD_PROVIDER') == "GCP" and pillar['OS'] == 'redhat8' %}
format-additional-disk:
  cmd.run:
    - name: mkfs.xfs /dev/sdb

create-additional-disk-mount-point:
  file.directory:
    - name: /mnt/tmp/

mount-additional-disk:
  cmd.run:
    - name: mount /dev/sdb /mnt/tmp/
{% else %}
nop-for-mount-workaround:
  test.nop:
    - name: "NOP - Mount workaround not needed for {{ salt['environ.get']('CLOUD_PROVIDER') }} {{ pillar['OS'] }}"
{% endif %}
