install_python_pip:
  pkg.installed:
    - pkgs:
    {% if grains['os_family'] == 'RedHat' %}
      - openssl-devel
      {% if grains['os'] == 'Amazon' %}
      - python27-devel
      - python27-pip
      {% elif grains['osmajorrelease'] | int == 6 %}
      - python-pip
      {% elif grains['osmajorrelease'] | int == 7 %}
      - python2-pip
      {% endif%}
    {% elif grains['os_family'] == 'Debian' %}
      - python-pip
    {% endif %}

{% if grains['os'] != 'Amazon' %}
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
