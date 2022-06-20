{% if pillar['OS'] == 'redhat8' %}  
install_jinja2:
  cmd.run:
    - name: python3 -m pip install jinja2
{% else %}
install_jinja2:
  cmd.run:
    - name: pip install jinja2
{% endif %}