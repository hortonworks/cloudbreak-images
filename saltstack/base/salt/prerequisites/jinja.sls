{% if pillar['OS'] == 'redhat8' %}  
install_jinja2:
  pip.installed:
    - name: jinja2
{% endif %}