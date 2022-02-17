{% if grains['os'] == 'CentOS' %}

set_centos_nologin_shell:
  user.present:
    - name: centos
    - shell: /usr/sbin/nologin

{% endif %}
