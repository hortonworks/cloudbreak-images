oscap_scan:
  pkg.installed:
    - pkgs:
      - wget
      - bzip2
      - openscap-scanner
      - scap-security-guide

  file.directory:
    - name: /tmp/oscap
    - mode: 755

openscap_run_cis_l1:
  cmd.run:
    - name: |
        sudo oscap xccdf eval \
          --profile xccdf_org.ssgproject.content_profile_cis_server_l1 \
          --results /tmp/oscap/oscap_cis_l1_results.xml \
          --report /tmp/oscap/oscap_cis_l1_report.html \
          /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml | tee /tmp/oscap/oscap_cis_l1_log.txt
    - require:
      - pkg: oscap_scan
      - file: oscap_scan

{% if salt['environ.get']('STIG_ENABLED') == 'true' %}
openscap_info:
  cmd.run:
    - name: oscap info /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml
    - require:
      - pkg: oscap_scan

openscap_run_stig:
  cmd.run:
    - name: |
        sudo oscap xccdf eval \
          --profile xccdf_org.ssgproject.content_profile_stig \
          --results /tmp/oscap/oscap_stig_results.xml \
          --report /tmp/oscap/oscap_stig_report.html \
          /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml | tee /tmp/oscap/oscap_stig_log.txt
    - require:
      - pkg: oscap_scan
      - file: oscap_scan
{% endif %}

{% set os_type = salt['environ.get']('OS_TYPE') %}
{% if os_type == 'redhat9' %}
  {% set oval_url = 'https://security.access.redhat.com/data/oval/v2/RHEL9/rhel-9.6-eus.oval.xml.bz2' %}
  {% set oval_file = 'rhel-9.6-eus.oval.xml' %}
{% else %}
  {% set oval_url = 'https://security.access.redhat.com/data/oval/v2/RHEL8/rhel-8.oval.xml.bz2' %}
  {% set oval_file = 'rhel-8.oval.xml' %}
{% endif %}

openscap_cve_scan:
  cmd.run:
    - name: |
        cd /tmp/oscap && \
        wget -q -O {{ oval_file }}.bz2 {{ oval_url }} && \
        bunzip2 -f {{ oval_file }}.bz2 && \
        oscap oval eval \
          --results /tmp/oscap/oscap_cve_results.xml \
          --report /tmp/oscap/oscap_cve_report.html \
          /tmp/oscap/{{ oval_file }}
    - require:
      - pkg: oscap_scan
      - file: oscap_scan

openscap_log_and_report_chmod:
  cmd.run:
    - name: chmod 777 /tmp/oscap/oscap_*
    - file: oscap_scan

oscap_scan_cleanup:
  pkg.removed:
    - pkgs:
      - wget
      - openscap-scanner
      - scap-security-guide
