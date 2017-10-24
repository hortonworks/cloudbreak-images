{% if grains['os_family'] == 'RedHat' %}

yum_cleanup_all:
  cmd.run:
    - name: yum clean all

{% elif grains['os_family'] == 'Debian' %}
apt_cleanup_all:
  cmd.run:
    - name: apt-get clean
{% endif %}
