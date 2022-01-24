{% if grains['os_family'] == 'RedHat' %}
create_clustermanager_repo:
  pkgrepo.managed:
    - name: clustermanager
    - humanname: "CLUSTERMANAGER.{{ pillar['CLUSTERMANAGER_VERSION'] }}"
    - baseurl: "{{ pillar['CLUSTERMANAGER_BASEURL'] }}"
    - gpgcheck: 1
    - gpgkey: "{{ pillar['CLUSTERMANAGER_GPGKEY'] }}"
    - priority: 1
{% elif grains['os_family'] == 'Debian' %}
create_clustermanager_repo:
  pkgrepo.managed:
    - humanname: "CLUSTERMANAGER.{{ pillar['CLUSTERMANAGER_VERSION'] }}"
    - name: "deb {{ pillar['CLUSTERMANAGER_BASEURL'] }} clustermanager main"
    - file: /etc/apt/sources.list.d/clustermanager.list
    - keyid: "{{ pillar['CLUSTERMANAGER_GPGKEY'] }}"
    - keyserver: keyserver.ubuntu.com
    - priority: 1
{% endif %}

install_clustermanager_pgks:
  pkg.installed:
    - pkgs:
      - cloudera-manager-daemons
      - cloudera-manager-agent
      - cloudera-manager-server
    - require:
      - pkgrepo: create_clustermanager_repo

disable_clustermanager_server:
  service.dead:
    - enable: False
    - name: cloudera-scm-server

disable_clustermanager_agent:
  service.dead:
    - enable: False
    - name: cloudera-scm-agent