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

{%- set ssh_banner | indent(8) -%}
{%- if salt['environ.get']('CLOUD_PROVIDER') == 'AWS_GOV' -%}
You are accessing a U.S. Government (USG) Information System (IS) that is provided for USG-authorized use only.

By using this IS (which includes any device attached to this IS), you consent to the following conditions:
-The USG routinely intercepts and monitors communications on this IS for purposes including, but not limited to, penetration testing, COMSEC monitoring, network operations and defense, personnel misconduct (PM), law enforcement (LE), and counterintelligence (CI) investigations.
-At any time, the USG may inspect and seize data stored on this IS.
-Communications using, or data stored on, this IS are not private, are subject to routine monitoring, interception, and search, and may be disclosed or used for any USG-authorized purpose.
-This IS includes security measures (e.g., authentication and access controls) to protect USG interests--not for your personal benefit or privacy.
-Notwithstanding the above, using this IS does not constitute consent to PM, LE or CI investigative searching or monitoring of the content of privileged communications, or work product, related to personal representation or services by attorneys, psychotherapists, or clergy, and their assistants. Such communications and work product are private and confidential. See User Agreement for details.
{%- else -%}
Corporate computer security personnel monitor this system for security purposes to ensure it remains available to all users and to protect information in the system. By accessing this system, you are expressly consenting to these monitoring activities.
Unauthorized attempts to defeat or circumvent security features, to use the system for other than intended purposes, to deny service to authorized users, to access, obtain, alter, damage, or destroy information, or otherwise to interfere with the system or its operation are prohibited. Evidence of such acts may be disclosed to law enforcement authorities and result in criminal prosecution under the Computer Fraud and Abuse Act of 1986 (Pub. L. 99-474) and the National Information Infrastructure Protection Act of 1996 (Pub. L. 104-294), (18 U.S.C. 1030), or other applicable criminal laws.
{%- endif -%}
{%- endset %}

sshd_local_WarnBanner1:
  file.managed:
    - name: /etc/issue
    - contents: |
        {{ ssh_banner }}

sshd_local_WarnBanner2:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^Banner.*"
    - repl: "Banner /etc/issue.net"
    - append_if_not_found: True

sshd_remote_WarnBanner:
  file.managed:
    - name: /etc/issue.net
    - contents: |
        {{ ssh_banner }}

