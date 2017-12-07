{% if grains['os_family'] == 'RedHat' %}
{% if grains['osmajorrelease'] == '6' or grains['os'] == 'Amazon' %}
HDP-UTILS:
  pkgrepo.managed:
    - humanname: HDP-UTILS-1.1.0.21
    - baseurl: http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.21/repos/centos6
    - gpgcheck: 0
{% elif  grains['osmajorrelease'] == '7' %}
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

{% endif %}
