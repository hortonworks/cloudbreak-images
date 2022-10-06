# This file could be probably dropped altogether - it tries to install/update ancient versions of pip
# and also, PyYAML gets installed earlier anyway.
# Maybe the last, jq part could be useful, but it shouldn't be here anyway...

{% if grains['os_family'] == 'RedHat' %}
install_openssl_devel:
  pkg.installed:
    - pkgs:
      - openssl-devel
{% endif %}

{% if grains['os'] | upper == 'SUSE' %}
update_python_pip2:
  cmd.run:
    - name: pip2 install --upgrade --index=https://pypi.python.org/simple/ pip==9.0.3
    - onlyif: pip2 -V

update_python_pip3:
  cmd.run:
    - name: pip3 install --upgrade --index=https://pypi.python.org/simple/ pip==9.0.3
    - onlyif: pip3 -V

{% elif grains['os'] != 'Amazon' and not salt['file.directory_exists']('/yarn-private') %}
update_python_pip2:
  cmd.run:
    - name: pip2 install --upgrade --index=https://pypi.python.org/simple/ pip==8.1.2
    - onlyif: pip2 -V

update_python_pip3:
  cmd.run:
    - name: pip3 install --upgrade --index=https://pypi.python.org/simple/ pip==8.1.2
    - onlyif: pip3 -V

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
