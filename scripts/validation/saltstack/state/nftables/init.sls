# CB-35393: Validate the CVE-2026-98432 nftables mitigation, see https://access.redhat.com/security/vulnerabilities/RHSB-2026-016
{% set os = salt['environ.get']('OS') %}
{% if (os == 'redhat8' or os == 'redhat9') and not salt['file.directory_exists']('/yarn-private') %}

check_cve_2026_98432_nft_file_syntax:
  cmd.run:
    - name: nft --check --file /etc/nftables/cve-2026-98432.nft
    - failhard: True

check_cve_2026_98432_nft_table_loaded:
  cmd.run:
    - name: nft list table inet cve_2026_98432 | grep -E 'hdrlength > 5 .*drop'
    - failhard: True

check_cve_2026_98432_nft_rule_persisted:
  cmd.run:
    - name: grep -Fx 'include "/etc/nftables/cve-2026-98432.nft"' /etc/sysconfig/nftables.conf
    - failhard: True

check_nftables_service_enabled:
  cmd.run:
    - name: systemctl is-enabled nftables
    - failhard: True

{% endif %}
