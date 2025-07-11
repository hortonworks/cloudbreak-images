{% set freeipa_ldapagent_rpm_url = salt['environ.get']('FREEIPA_LDAP_AGENT_RPM_URL') %}


{% if freeipa_ldapagent_rpm_url %}
/etc/httpd/conf/httpd-log-filter.sh:
  file.managed:
    - name: /etc/httpd/conf/httpd-log-filter.sh
    - makedirs: True
    - user: root
    - group: root
    - mode: 700
    - source: salt://selinux/httpd-log-filter.sh

{% endif %}

/cdp/ipahealthagent/httpd-crt-tracking.sh:
  file.managed:
    - name: /cdp/ipahealthagent/httpd-crt-tracking.sh
    - makedirs: True
    - user: root
    - group: root
    - mode: 700
    - source: salt://selinux/httpd-crt-tracking.sh