{% if grains['os_family'] == 'RedHat' %}
install_selinux_module_dependecies:
  test.succeed_without_changes:
    - pkg.installed:
      - pkgs:
        - policycoreutils
        - policycoreutils-python

selinux.setenforce:
  module.run:
    - mode: Disabled

disable_selinux:
  file.replace:
    - name: /etc/sysconfig/selinux
    - pattern: "^SELINUX.*"
    - repl: "SELINUX=Disabled"
    - append_if_not_found: True
{% endif %}
