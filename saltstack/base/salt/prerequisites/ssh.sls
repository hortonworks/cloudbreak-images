sshd_configure_addressfamily:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "#AddressFamily.*"
    - repl: "AddressFamily inet"
    - append_if_not_found: True

sshd_configure_usedns_replace:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^UseDNS yes"
    - repl: "UseDNS no"
    - append_if_not_found: True

sshd_configure_gssapiauthentication_replace:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^GSSAPIAuthentication yes"
    - repl: "GSSAPIAuthentication no"
    - append_if_not_found: True

#Root user login via SSH needs to be disabled from version 7.2.8
{% set version = salt['environ.get']('STACK_VERSION') %}
{% if pillar['CUSTOM_IMAGE_TYPE'] == 'freeipa' or (version and version.split('.') | map('int') | list >= [7, 2, 8]) %}
sshd_harden_PermitRootLogin:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^PermitRootLogin.*"
    - repl: "PermitRootLogin no"
    - append_if_not_found: True
{% else %}
# Place motd-login file that will be used by user-data-helper.sh
/etc/motd-login:
  file.managed:
    - contents: |
        Please either login with the default "cloudbreak" user or an SSO user, rather than the user "root".
{%- endif %}

sshd_local_WarnBanner1:
  file.managed:
    - name: /etc/issue
    - template: jinja
    - source: salt://{{ slspath }}/etc/issue

sshd_local_WarnBanner2:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^Banner.*"
    - repl: "Banner /etc/issue.net"
    - append_if_not_found: True

sshd_remote_WarnBanner:
  file.managed:
    - name: /etc/issue.net
    - template: jinja
    - source: salt://{{ slspath }}/etc/issue

