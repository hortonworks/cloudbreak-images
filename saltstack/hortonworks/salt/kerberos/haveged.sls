{% if grains['os_family'] != 'Debian' %}
install_haveged_packages:
  pkg.installed:
    - pkgs:
      - haveged
{% if grains['os'] == 'Amazon' %}
    - fromrepo: epel
{% endif %}

service_haveged:
  service.enabled:
    - name: haveged
    - require:
      - pkg: install_haveged_packages
{% endif %}
