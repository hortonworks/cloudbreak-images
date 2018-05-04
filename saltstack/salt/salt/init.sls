# This part is for later use, when the salt version would be different from the version given in the Makefile
#{% if grains['os_family'] == 'RedHat' %}
#{% if grains['osmajorrelease'] == '7' %}
#install_salt_repository:
#  pkg.installed:
#    - sources:
#      - salt-repo: https://repo.saltstack.com/yum/redhat/salt-repo-latest-2.el7.noarch.rpm
#    - require_in:
#      - pkg: install_salt_components
#{% elif grains['osmajorrelease'] == '6' %}
#install_salt_repository:
#  pkg.installed:
#    - sources:
#      - salt-repo: https://repo.saltstack.com/yum/redhat/salt-repo-latest-2.el6.noarch.rpm
#    - require_in:
#      - pkg: install_salt_components
#{% endif%}
#{% elif grains['os'] == 'Debian' %}
#{% if grains['osmajorrelease'] == '7' %}
#install_salt_repository:
#  pkgrepo.managed:
#  - humanname: Salt components repo
#  - name: deb http://repo.saltstack.com/apt/debian/7/amd64/latest wheezy main
#  - dist: wheezy
#  - file: /etc/apt/sources.list.d/saltstack.list
#  - require_in:
#  - pkg: install_salt_components
#  - gpgcheck: 1
#  - key_url: http://repo.saltstack.com/apt/debian/7/amd64/latest/SALTSTACK-GPG-KEY.pub
#{% endif %}
#{% elif grains['os'] == 'Ubuntu' %}
#{% if grains['osmajorrelease'] == '12' %}
#install_salt_repository:
#  pkgrepo.managed:
#  - humanname: Salt components repo
#  - name: deb http://repo.saltstack.com/apt/ubuntu/12.04/amd64/latest precise main
#  - dist: precise
#  - file: /etc/apt/sources.list.d/saltstack.list
#  - require_in:
#  - pkg: install_salt_components
#  - gpgcheck: 1
#  - key_url: http://repo.saltstack.com/apt/ubuntu/12.04/amd64/latest/SALTSTACK-GPG-KEY.pub
#{% elif grains['osmajorrelease'] == '14' %}
#install_salt_repository:
#  pkgrepo.managed:
#  - humanname: Salt components repo
#  - name: deb http://repo.saltstack.com/apt/ubuntu/14.04/amd64/latest trusty main
#  - dist: trusty
#  - file: /etc/apt/sources.list.d/saltstack.list
#  - require_in:
#  - pkg: install_salt_components
#  - gpgcheck: 1
#  - key_url: http://repo.saltstack.com/apt/ubuntu/14.04/amd64/latest/SALTSTACK-GPG-KEY.pub
#{% endif %}
#{% endif %}

install_salt_components:
  pkg.installed:
    - pkgs:
      - salt-master
      - salt-minion
      - salt-api

#ensure_salt-master_is_dead:
#  service.dead:
#    - name: salt-master

ensure_salt-master_is_disabled:
  service.disabled:
    - name: salt-master


ensure_salt-minion_is_dead:
  service.dead:
    - name: salt-minion
ensure_salt-minion_is_disabled:
  service.disabled:
    - name: salt-minion


/etc/salt:
  file.recurse:
    - source: salt://{{ slspath }}/etc/salt
    - template: jinja
    - include_empty: True
