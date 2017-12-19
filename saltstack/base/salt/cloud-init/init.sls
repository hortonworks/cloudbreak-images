install_cloud-init_packages:
  pkg.installed:
    - pkgs:
      - cloud-init
    {% if grains['os_family'] == 'Debian' and  grains['osmajorrelease'] | int == 7 %}
    - fromrepo: wheezy-backports
    {% endif %}

preserve_hostname_false:
  file.replace:
    - name: /etc/cloud/cloud.cfg
    - pattern: "^preserve_hostname.*"
    - repl: "preserve_hostname: true"
    - append_if_not_found: True

create_cloudbreak_files:
  file.managed:
    - user: root
    - group: root
    - name: /etc/cloud/cloud.cfg.d/50_cloudbreak.cfg
    - source: salt://{{ slspath }}/etc/cloud/cloud.cfg.d/50_cloudbreak.cfg

{% if grains['init'] == 'systemd' %}
create_cloud-init_service_files:
  file.managed:
    - user: root
    - group: root
    - name: /etc/systemd/system/cloud-init.service
    - source: salt://{{ slspath }}/etc/systemd/system/cloud-init.service
    - unless: ls /etc/waagent.conf
{% endif %}