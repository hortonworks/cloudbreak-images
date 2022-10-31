{% if '/usr/sbin' not in salt['environ.get']('PATH') %}
set_path_sbin:
  environ.setenv:
    - name: PATH
    - value: "{{ salt['environ.get']('PATH') }}:/usr/sbin"
    - update_minion: True
{% endif %}

{% if '/usr/local/sbin' not in salt['environ.get']('PATH') %}
set_path_local_sbin:
  environ.setenv:
    - name: PATH
    - value: "{{ salt['environ.get']('PATH') }}:/usr/local/sbin:/usr/local/bin"
    - update_minion: True
{% endif %}
