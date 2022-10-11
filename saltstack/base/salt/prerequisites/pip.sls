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
    - source_hash: md5=89c7bb6138fa6a5c989aca6b71586acc
    - skip_verify: True
    - mode: 755
