create_clustermanager_repo:
  pkgrepo.managed:
    - name: clustermanager
    - humanname: "CLUSTERMANAGER.{{ pillar['CLUSTERMANAGER_VERSION'] }}"
    - baseurl: "{{ pillar['CLUSTERMANAGER_BASEURL'] }}"
    - gpgcheck: 1
    - gpgkey: "{{ pillar['CLUSTERMANAGER_GPGKEY'] }}"
    - priority: 1

{% if salt['environ.get']('ARCHITECTURE') != 'arm64' or salt['environ.get']('OS') != 'redhat9' %}
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
{% else %}
create_dummy_cm_agent_dir:
  file.directory:
    - name: /var/lib/cloudera-scm-agent
    - mode: 755

create_dummy_cm_agent_parcel_config:
  file.managed:
    - name: /var/lib/cloudera-scm-agent/active_parcels.json
    - contents: '' # Creates an empty file.
    - require:
      - file: /var/lib/cloudera-scm-agent
{% endif %}