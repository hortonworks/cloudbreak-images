{% if grains['os_family'] == 'RedHat' %}

yum_cleanup_all:
  cmd.run:
    - name: yum clean all

{% elif grains['os_family'] == 'Debian' %}

apt_cleanup_all:
  cmd.run:
    - name: apt-get clean

{% elif grains['os_family'] == 'Suse' %}

zypper_cleanup_all:
  cmd.run:
    - name: zypper clean

deregister_system:
  cmd.run:
    - name: SUSEConnect -d
    - onlyif: '[[ "x${SLES_REGISTRATION_CODE}" != "x" ]] && SUSEConnect -s | grep -q \"Registered\"'

{% endif %}
