install_ad_packages:
  pkg.installed:
    - pkgs:
      - sssd
      - realmd
      - krb5-workstation
      - samba-common-tools
      - openldap-clients