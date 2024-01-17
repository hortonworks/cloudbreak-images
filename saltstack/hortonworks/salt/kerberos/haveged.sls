install_haveged_packages:
  pkg.installed:
    - pkgs:
      - haveged
{% if grains['os'] == 'Amazon' %}
    - fromrepo: epel
{% endif %}    

service_haveged:
{% if pillar['subtype'] != 'Docker' %}
  service.enabled:
    - name: haveged
{% else %}
  cmd.run:
    - name: systemctl enable haveged
{% endif %}
    - require:
      - pkg: install_haveged_packages
