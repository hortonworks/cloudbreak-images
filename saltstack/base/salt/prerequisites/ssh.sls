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