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

httpd-log-filter-setup:
  cmd.run:
    - name: semanage fcontext -a -t httpd_sys_script_exec_t '/etc/httpd/conf/httpd-log-filter.sh' && restorecon -v /etc/httpd/conf/httpd-log-filter.sh && semodule -B
{% endif %}