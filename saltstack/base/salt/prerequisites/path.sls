{% set path = salt['environ.get']('PATH') %}

{% if '/usr/sbin' not in path %}
  {% set path = path ~ ':/usr/sbin' %}
{% endif %}

{% if '/usr/local/sbin' not in path %}
  {% set path = path ~ ':/usr/local/sbin' %}
{% endif %}

/root/.bashrc:
  file.append:
    - text: "export PATH={{ path }}"

refresh_profile:
  cmd.run:
    - name: source /root/.bashrc
