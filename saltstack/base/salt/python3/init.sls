{% if grains['init'] == 'systemd' -%}
set_python3_path_systemd:
  file.replace:
    - name: /etc/systemd/system.conf
    - pattern: \#+DefaultEnvironment=.*
    - repl: DefaultEnvironment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/opt/rh/rh-python38/root/usr/local/bin:/opt/rh/rh-python38/root/usr/bin
    - onlyif: ls -la /opt/rh/rh-python38/root/usr/local/
{% endif %}

# Install distro globally

# CentOS 7 / RHEL 7 / RHEL 8 + Python 3.6
distro-centos7-py36:
  pip.installed:
    - name: distro
    - bin_env: /usr/local/bin/pip3
    - onlyif: ls -la /usr/local/lib/python3.6/site-packages/

# RHEL 8 + Python 3.8
# For RHEL 8 this is installed in salt-install.sh, because it is required for Salt

# CentOS 7 + Python 3.8
distro-centos7-py38:
  pip.installed:
    - name: distro
    - bin_env: /opt/rh/rh-python38/root/usr/bin/pip3
    - onlyif: ls -la /opt/rh/rh-python38/root/usr/lib/python3.8/site-packages/
