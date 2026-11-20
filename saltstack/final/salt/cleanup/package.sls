{% if salt['environ.get']('OS') == 'redhat8' or salt['environ.get']('OS') == 'redhat9' %}

dnf_cleanup_all:
  cmd.run:
    - name: dnf autoremove --assumeno

{% endif %}
