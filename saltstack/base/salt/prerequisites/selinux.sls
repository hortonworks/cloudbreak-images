{% if grains['os_family'] == 'RedHat' %}
install_selinux_module_dependecies:
  pkg.installed:
    - pkgs:
      - policycoreutils
      - policycoreutils-python

selinux.setenforce:
  module.run:
    - mode: Disabled
    - require:
      - pkg: install_selinux_module_dependecies

disable_selinux_type:
  file.replace:
    - name: /etc/sysconfig/selinux
    - pattern: "^SELINUXTYPE.*"
    - repl: "#SELINUXTYPE="
    - append_if_not_found: False
    - require:
      - pkg: install_selinux_module_dependecies

disable_selinux:
  file.replace:
    - name: /etc/sysconfig/selinux
    - pattern: "^SELINUX.*"
    - repl: "SELINUX=Disabled"
    - append_if_not_found: True
    - require:
      - pkg: install_selinux_module_dependecies
{% endif %}
