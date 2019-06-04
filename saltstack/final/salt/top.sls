final:
  '*':
{% if pillar['CUSTOM_IMAGE_TYPE'] != 'freeipa' %}
    - validate
{% endif %}    
{% if salt['file.file_exists']('/etc/waagent.conf') %}
    - waagent
{% endif %}
    - cleanup
