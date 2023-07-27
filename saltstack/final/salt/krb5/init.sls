# Disable new kerberos caching behavior on RHEL8, 
# so the logic will be the same as it is on CentOS 7
{% if pillar['OS'] == 'redhat8' %}
disable_kcm_ccache:
  file.absent:
    - name: /etc/krb5.conf.d/kcm_default_ccache
{% endif %}
