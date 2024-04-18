{% if salt['environ.get']('STIG_ENABLED') == 'true' %}
set_hardening_to_stig:
  file.managed:
    - name: /var/log/hardening
    - contents:
      - "stig"
{% endif %}