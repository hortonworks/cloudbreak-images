final:
  '*':
{% if pillar['IMAGE_TYPE'] != 'freeipa' %}
    - validate
{% endif %}
    - krb5
    - metadata
{% if pillar['subtype'] != 'Docker'  %}
    - cis-controls
{% if salt['environ.get']('OSCAP_SCAN_ENABLED') == 'true' %}
    - openscap
{% endif %}
{% endif %}
{% if salt['file.file_exists']('/etc/waagent.conf') %}
    - waagent
{% endif %}
    - cleanup
    - hacks-and-tweaks
