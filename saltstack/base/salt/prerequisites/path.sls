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
    - value: "{{ salt['environ.get']('PATH') }}:/usr/local/sbin"
    - update_minion: True
{% endif %}

# Needed for installing psycopg2 in saltstack/base/salt/postgresql/init.sls
{% if '/usr/pgsql-11/bin' not in salt['environ.get']('PATH') %}
set_path_pgsql11_bin:
  environ.setenv:
    - name: PATH
    - value: "{{ salt['environ.get']('PATH') }}:/usr/pgsql-11/bin"
    - update_minion: True
{% endif %}