# Disable new kerberos caching behavior on RHEL8, 
# so the logic will be the same as it is on CentOS 7
{% if pillar['OS'] == 'redhat8' %}
disable_kcm_ccache:
  file.absent:
    - name: /etc/krb5.conf.d/kcm_default_ccache

disable_sssd_conf_dir:
  file.absent:
    - name: /etc/krb5.conf.d/enable_sssd_conf_dir

{% if salt['environ.get']('DEFAULT_JAVA_MAJOR_VERSION') == '8' and salt['environ.get']('RHEL_VERSION') == '8.10' %}
change_krb5_conf_crypto_policies:
  file.managed:
    - name: /etc/krb5.conf.d/crypto-policies
    - replace: True
    - contents: |
        [libdefaults]
        permitted_enctypes = aes256-cts-hmac-sha1-96 aes256-cts-hmac-sha384-192 camellia256-cts-cmac aes128-cts-hmac-sha1-96 aes128-cts-hmac-sha256-128 camellia128-cts-cmac
{% endif %}
{% endif %}
