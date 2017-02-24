install_python_pip:
  pkg.installed:
    - pkgs:
    {% if grains['os_family'] == 'RedHat' %}
      - openssl-devel
      {% if grains['os'] == 'Amazon' %}
      - python27-devel
      - python27-pip
      {% elif grains['osmajorrelease'] == '6' %}
      - python-pip
      - python-devel
      {% elif grains['osmajorrelease'] == '7' %}
      - python2-pip
      {% endif%}
    {% elif grains['os_family'] == 'Debian' %}
      - python-pip
    {% endif %}

pip_install_requests_security:
  pip.installed:
    - pkgs:
      - requests[security]

pip_install_virtualenvwrapper:
  pip.installed:
    - name: virtualenvwrapper
