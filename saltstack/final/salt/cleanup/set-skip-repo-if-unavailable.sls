{% if grains['os_family'] == 'RedHat' %}

set_skip_if_unavailable:
  cmd.run:
    - name: grep -Pho '(?<=\[).*(?=\])' /etc/yum.repos.d/* |  xargs  -I{}  -t  yum-config-manager --save --setopt={}.skip_if_unavailable=true >/dev/null 2>&1 || true

{% endif %}
