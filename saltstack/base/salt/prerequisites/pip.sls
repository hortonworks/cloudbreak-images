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
  file.managed:
    - name: /usr/bin/jq
    - source: https://github.com/jqlang/jq/releases/download/jq-1.6/jq-linux64
    - source_hash: sha256=af986793a515d500ab2d35f8d2aecd656e764504b789b66d7e1a0b727a124c44
    - mode: 755
