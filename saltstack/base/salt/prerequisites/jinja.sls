{% if pillar['OS'] == 'redhat8' or pillar['OS'] == 'redhat9' or pillar['OS'] == 'redhat10' %}  
install_jinja2:
  pip.installed:
    - name: jinja2
{% endif %}