{% if grains['os_family'] == 'RedHat' %}

install_selinux_module_dependecies:
  pkg.installed:
    - pkgs:
      - policycoreutils
      - selinux-policy-devel
{% if pillar['OS'] == 'redhat8' %}
      - policycoreutils-python-utils
{% else %}
      - policycoreutils-python
{% endif %}

selinux_permissive:
  selinux.mode:
    - name: permissive
    - require:
      - pkg: install_selinux_module_dependecies

map_root_to_system_u:
  cmd.run:
    - name: semanage login -m -s system_u root

{% endif %}
