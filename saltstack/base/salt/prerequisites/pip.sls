install_python_pip:
  pkg.installed:
    - pkgs:
    {% if grains['os_family'] == 'RedHat' %}
      - openssl-devel
      {% if pillar['OS'] == 'amazonlinux2' %}
      - python2-pip
      {% elif grains['os'] == 'Amazon' %}
      - python27-devel
      - python27-pip
      {% elif grains['osmajorrelease'] | int == 6 %}
      - python-pip
      {% elif grains['osmajorrelease'] | int == 7 %}
      - python2-pip
      {% endif%}
    {% elif grains['os_family'] == 'Debian' %}
      - python-pip
    {% elif grains['os_family'] == 'Suse' %}
      - python-pip
    {% endif %}

{% if grains['os'] != 'Amazon' and grains['os_family'] != 'Suse' %}
update_python_pip:
  cmd.run:
    - name: pip install --upgrade --index=https://pypi.python.org/simple/ pip==8.1.2

{% endif %}

pip_install_requests_security:
  pip.installed:
    - pkgs:
      - requests[security]

pip_install_virtualenvwrapper:
  pip.installed:
    - name: virtualenvwrapper

install_jq:
  file.managed:
    - name: /usr/bin/jq
    - source: http://stedolan.github.io/jq/download/linux64/jq
    - skip_verify: True
    - mode: 755
