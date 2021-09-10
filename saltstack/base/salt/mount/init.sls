{% set platform = salt['grains.filter_by']({
    'amazon-ebs': {
        'required': True
    },
    'azure-arm': {
        'required': False,
    },
    'googlecompute': {
        'required': False,
    },
},
grain='builder_type',
default='amazon-ebs'
)%}

{% if platform.required and pillar['OS'] == 'centos7' %}
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
{% else %}
nop-for-mount-workaround-on-other-platforms:
  test.nop:
    - name: "NOP - Mount workaround only needed on AWS"
{% endif %}