update-kernel:
  cmd.run:
    {% if grains['os_family'] == 'RedHat' %}
    - name: yum -y update kernel
    {% elif grains['os_family'] == 'Debian' %}
    - name: apt-get update && apt-get dist-upgrade -y
    {% else %}
    - name: echo "Not supported os, no kernel update"
    {% endif %}
