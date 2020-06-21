{% if pillar['OS'] == 'centos7' and pillar['subtype'] != 'Docker' %}
install_cloud-init_packages:
  pkg.installed:
    - sources:
      - cloud-init: http://vault.centos.org/7.5.1804/os/x86_64/Packages/cloud-init-0.7.9-24.el7.centos.x86_64.rpm
    - skip_verify: True
    - allow_updates: True
    - hold: False
{% else %}
install_cloud-init_packages:
  pkg.installed:
    - pkgs:
      - cloud-init
    {% if grains['os'] == 'Debian' and  grains['osmajorrelease'] | int == 7 %}
    - fromrepo: wheezy-backports
    {% endif %}
{% endif %}

preserve_hostname_false:
  file.replace:
    - name: /etc/cloud/cloud.cfg
    - pattern: "^preserve_hostname.*"
    - repl: "preserve_hostname: true"
    - append_if_not_found: True

{% if pillar['subtype'] == 'Docker' %}
set_datasource_to_fallback:
  file.replace:
{% if grains['os_family'] == 'Debian' %}
    - name: /etc/cloud/cloud.cfg.d/90_dpkg.cfg
{% else %}
    - name: /etc/cloud/cloud.cfg
{% endif %}
    - pattern: "^datasource_list.*"
    - repl: "datasource_list: [ None ]"
    - append_if_not_found: True

disable_resolv_conf_update:
  file.replace:
    - name: /etc/cloud/cloud.cfg
    - pattern: "^manage_resolv_conf:.*"
    - repl: "manage_resolv_conf: false"
    - append_if_not_found: True
{% endif %}

create_cloudbreak_files:
  file.managed:
    - user: root
    - group: root
    - name: /etc/cloud/cloud.cfg.d/50_cloudbreak.cfg
    - source: salt://{{ slspath }}/etc/cloud/cloud.cfg.d/50_cloudbreak.cfg

create_scripts:
  file.managed:
    - user: root
    - group: root
    - mode: 744
    - name: /var/lib/cloud/scripts/per-instance/extract.sh
    - source: salt://{{ slspath }}/etc/scripts/extract.sh

{% if grains['init'] == 'systemd' %}
create_cloud-init_service_files:
  file.managed:
    - user: root
    - group: root
    - name: /etc/systemd/system/cloud-init.service
    - source: salt://{{ slspath }}/etc/systemd/system/cloud-init.service
{% endif %}
