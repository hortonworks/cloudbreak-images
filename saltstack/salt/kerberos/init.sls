install_kerberos_packages:
  pkg.installed:
    - pkgs:
      {% if grains['os_family'] == 'RedHat' %}
      - krb5-server
      - krb5-libs
      - krb5-workstation
      {% elif grains['os_family'] == 'Debian' %}
        - krb5-admin-server
        - krb5-kdc
      {% endif %}
