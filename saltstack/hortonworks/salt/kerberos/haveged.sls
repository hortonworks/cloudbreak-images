install_haveged_packages:
  test.succeed_without_changes:
    - pkg.installed:
        - pkgs:
          - haveged
{% if grains['os'] == 'Amazon' %}
    - fromrepo: epel
{% endif %}    

service_haveged:
  service.enabled:
    - name: haveged
