{% if grains['init'] in [ 'upstart', 'sysvinit'] %}
tmp_mount_fstab:
  file.replace:
    - name: /etc/fstab
    - pattern: ".*/tmp.*"
    - repl: "tmpfs       /tmp       tmpfs   mode=defaults,strictatime,nosuid,nodev,noexec,size=1G        0   0"
    - append_if_not_found: True

{% elif grains['init'] == 'systemd' %}

{% if grains['os_family'] == 'Debian' %}
/lib/systemd/system/tmp.mount:
  file.symlink:
    - target: /usr/share/systemd/tmp.mount
    - force: True

service.systemctl_reload:
  module.run: []
{% endif %}

/etc/systemd/system/tmp.mount:
  file.absent: []

/etc/systemd/system/tmp.mount.d/options.conf:
  file.managed:
    - user: root
    - group: root
    - source:
      - salt://{{ slspath }}/etc/systemd/system/tmp.mount.d/options.conf
    - mode: 755
    - makedirs: True

enable_tmp_mount:
  service.enabled:
    - name: tmp.mount
    - require:
      - /etc/systemd/system/tmp.mount.d/options.conf

{% endif %}
