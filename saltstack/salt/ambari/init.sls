{% if grains['os_family'] == 'RedHat' %}
create_ambari_repo:
  pkgrepo.managed:
    - name: ambari
    - humanname: "AMBARI.{{ pillar['AMBARI_VERSION'] }}"
    - baseurl: "{{ pillar['AMBARI_BASEURL'] }}"
    - gpgcheck: 1
    - gpgkey: "{{ pillar['AMBARI_GPGKEY'] }}"
    - priority: 1
{% elif grains['os_family'] == 'Debian' %}
create_ambari_repo:
  pkgrepo.managed:
    - humanname: "AMBARI.{{ pillar['AMBARI_VERSION'] }}"
    - name: "deb {{ pillar['AMBARI_BASEURL'] }} Ambari main"
    - file: /etc/apt/sources.list.d/ambari.list
    - keyid: "{{ pillar['AMBARI_GPGKEY'] }}"
    - keyserver: keyserver.ubuntu.com
    - priority: 1
{% endif %}

install_ambari_pgks:
  pkg.installed:
    - pkgs:
      - ambari-server
      - ambari-agent
    - require:
      - pkgrepo: create_ambari_repo

disable_ambari_server:
  cmd.run:
    - name: chkconfig ambari-server off
    - onlyif: /sbin/chkconfig --list ambari-server | grep on

disable_ambari_agent:
  cmd.run:
    - name: chkconfig ambari-agent off
    - onlyif: /sbin/chkconfig --list ambari-agent | grep on

{% if grains['init'] == 'systemd' %}
/usr/lib/tmpfiles.d:
  file.recurse:
    - source: salt://{{ slspath }}/usr/lib/tmpfiles.d/
    - include_empty: True
{% endif %}

set_tlsv1_2:
  file.replace:
    - name: /etc/ambari-agent/conf/ambari-agent.ini
    - pattern: "\\[security\\]"
    - repl: "[security]\nforce_https_protocol=PROTOCOL_TLSv1_2"
    - unless: cat /etc/ambari-agent/conf/ambari-agent.ini | grep force_https_protocol

add_amazon_os_patch_script:
  file.managed:
    - name: /tmp/amazon_os.sh
    - source: salt://{{ slspath }}/tmp/amazon_os.sh
    - skip_verify: True
    - makedirs: True
    - mode: 755

run_amazon_os_sh:
  cmd.run:
    - name: sh -x /tmp/amazon_os.sh 2>&1 | tee -a /var/log/amazon_os_sh.log && exit ${PIPESTATUS[0]}
    - unless: ls /var/log/amazon_os_sh.log
    - require:
      - file: add_amazon_os_patch_script
