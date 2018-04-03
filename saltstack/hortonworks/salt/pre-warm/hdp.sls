# to create var/run/knox directory for Knox
{% if grains['init'] == 'systemd' %}
/usr/lib/tmpfiles.d/knox.conf:
  file.managed:
    - source: salt://pre-warm/gateway/systemd/knox.conf
{% endif %}

{% if pillar['REPOSITORY_TYPE'] == 'local' %}
install_hdp_prerequisite_packages:
  pkg.installed:
    - pkgs:
      - yum-utils
      - createrepo
      - httpd

configure_httpd:
  file.replace:
    - name:  /etc/httpd/conf/httpd.conf
    - pattern: "^Listen .*"
    - repl: "Listen 127.0.0.1:28080"
    - append_if_not_found: True
    - require:
      - install_hdp_prerequisite_packages

enable_httpd:
  service.running:
    - name: httpd
    - enable: True
    - require:
      - configure_httpd
{% endif %}

install_hdp:
  cmd.script:
    - name: salt://pre-warm/tmp/install_hdp.sh
    - template: jinja
    - env:
      - STACK_TYPE: "{{ pillar['STACK_TYPE'] }}"
      - HDP_STACK_VERSION: "{{ pillar['HDP_STACK_VERSION'] }}"
      - HDP_VERSION: {{ pillar['HDP_VERSION'] }}
      - HDP_BASEURL: {{ pillar['HDP_BASEURL'] }}
      - HDP_REPOID: {{ pillar['HDP_REPOID'] }}
      - MPACK_URLS: "{{ pillar['MPACK_URLS'] }}"
      - VDF: {{ pillar['VDF'] }}
      - REPOSITORY_VERSION: {{ pillar['REPOSITORY_VERSION'] }}
      - AMBARI_VERSION: {{ pillar['AMBARI_VERSION'] }}
      - OS: {{ pillar['OS'] }}
      - LOCAL_URL_AMBARI: {{ pillar['LOCAL_URL_AMBARI'] }}
      - LOCAL_URL_HDP: {{ pillar['LOCAL_URL_HDP'] }}
      - LOCAL_URL_HDP_UTILS: {{ pillar['LOCAL_URL_HDP_UTILS'] }}
      - LOCAL_URL_VDF: {{ pillar['LOCAL_URL_VDF'] }}
      - REPOSITORY_TYPE: {{ pillar['REPOSITORY_TYPE'] }}
    - output_loglevel: DEBUG
    - timeout: 9000
    - unless: ls /tmp/install_hdp.status
    - failhard: True
