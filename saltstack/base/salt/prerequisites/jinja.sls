{% if pillar['OS'] == 'redhat8' or pillar['OS'] == 'redhat9' %}  
install_jinja2:
  pip.installed:
    - name: jinja2
{% endif %}