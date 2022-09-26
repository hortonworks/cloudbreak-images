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
    - name: python3 -m pip install --upgrade --index=https://pypi.python.org/simple/ pip==8.1.2
    - onlyif: python3 -m pip -V

{% endif %}

{% if pillar['OS'] == 'redhat8' %}  
install_pyyaml:
  cmd.run:
    - name: python3 -m pip install "PyYAML>=5.1" --ignore-installed 
{% else %}
install_pyyaml:
  cmd.run:
    - name: pip install PyYAML --ignore-installed
    - unless: pip list | grep -E 'PyYAML'
{% endif %}

install_jq:
  file.managed:
    - name: /usr/bin/jq
    - source: https://stedolan.github.io/jq/download/linux64/jq
    - source_hash: md5=89c7bb6138fa6a5c989aca6b71586acc
    - skip_verify: True
    - mode: 755
