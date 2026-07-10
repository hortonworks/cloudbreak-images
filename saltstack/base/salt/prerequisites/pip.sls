{% if grains['os_family'] == 'RedHat' %}
install_openssl_devel:
  pkg.installed:
    - pkgs:
      - openssl-devel
{% endif %}

install_pyyaml:
  pip.installed:
    - name: PyYAML

install_jq:
  pkg.installed:
    - name: jq
