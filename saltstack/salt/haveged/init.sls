install_haveged_packages:
  pkg.installed:
    - pkgs: 
      - haveged

service_haveged:
  service.enabled:
    - name: haveged
    - require:
      - pkg: install_haveged_packages
