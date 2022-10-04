{% if pillar['OS'] == 'redhat8' %}
install_distro:
  cmd.run:
    - name: python3.8 -m pip install distro  
install_jinja2:
  cmd.run:
    - name: python3.8 -m pip install jinja2
{% else %}
install_jinja2:
  cmd.run:
    - name: pip install jinja2
{% endif %}