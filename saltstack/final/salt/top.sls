final:
  '*':
    - noexec-tmp
    - validate
{% if salt['file.file_exists']('/etc/waagent.conf') %}
    - waagent
{% endif %}
    - cleanup
