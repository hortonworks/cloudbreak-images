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

{% elif grains['os'] != 'Amazon' %}
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
  cmd.run:
    - name: pip install PyYAML --ignore-installed
    - unless: pip list | grep -E 'PyYAML'

install_psycopg2:
  cmd.run:
    - name: pip install psycopg2==2.7.5 --ignore-installed
    - unless: pip list --no-index | grep -E 'psycopg2.*2.7.5'


install_cm_client:
  cmd.run:
    - name: pip install cm-client==40.0.3 --ignore-installed
    - unless: pip list | grep -E 'cm-client.*40.0.3'

install_jq:
  file.managed:
    - name: /usr/bin/jq
    - source: http://stedolan.github.io/jq/download/linux64/jq
    - source_hash: md5=89c7bb6138fa6a5c989aca6b71586acc
    - skip_verify: True
    - mode: 755
