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
    - source: https://stedolan.github.io/jq/download/linux64/jq
    - source_hash: sha256=e96494ac4d485c1c06f8872bf00558ad95bb87e463c46fce071d8f24f0c4e3d6
    - skip_verify: True
    - mode: 755
