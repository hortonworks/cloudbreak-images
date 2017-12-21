{% if grains['os_family'] == 'RedHat' %}
{% if grains['osmajorrelease'] | int == 6 or grains['os'] == 'Amazon' %}
HDP-UTILS:
  pkgrepo.managed:
    - humanname: HDP-UTILS-1.1.0.21
    - baseurl: http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.21/repos/centos6
    - gpgcheck: 0
{% elif  grains['osmajorrelease'] | int == 7 %}
HDP-UTILS:
  pkgrepo.managed:
    - humanname: HDP-UTILS-1.1.0.21
    - baseurl: http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.21/repos/centos7
    - gpgcheck: 0
{% endif %}

epel_repo_package_install:
  pkg.installed:
    - pkgs:
      - epel-release

{% elif grains['os_family'] == 'Debian' and grains['osmajorrelease'] | int == 7 %}

install_wheezy_backports_repository:
  pkgrepo.managed:
    - humanname: Wheezy backports components repo
    - name: deb http://ftp.debian.org/debian wheezy-backports main contrib non-free
    - dist: wheezy-backports
    - file: /etc/apt/sources.list.d/wheezy_backports.list
    - gpgcheck: 1

apt_preference_wheezy_backports_repository:
  file.managed:
    - user: root
    - group: root
    - name: /etc/apt/preferences.d/wheezy-backports
    - source: salt://{{ slspath }}/etc/apt/preferences.d/wheezy-backports
    - mode: 644
{% endif %}