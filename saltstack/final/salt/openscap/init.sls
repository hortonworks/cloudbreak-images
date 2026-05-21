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

{% set os_type = salt['environ.get']('OS_TYPE') %}
{% if os_type == 'redhat9' %}
  {% set oval_url = 'https://security.access.redhat.com/data/oval/v2/RHEL9/rhel-9.6-eus.oval.xml.bz2' %}
  {% set oval_file = 'rhel-9.6-eus.oval.xml' %}
  {% set ssg_file = '/usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml' %}
{% else %}
  {% set oval_url = 'https://security.access.redhat.com/data/oval/v2/RHEL8/rhel-8.oval.xml.bz2' %}
  {% set oval_file = 'rhel-8.oval.xml' %}
  {% set ssg_file = '/usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml' %}
{% endif %}


# Add the Rule IDs you wish to exclude here.
{% set oscap_exceptions = [
  # Cloud Infrastructure Exceptions
  'xccdf_org.ssgproject.content_rule_partition_for_tmp',          # Single partition is standard for cloud images
  'xccdf_org.ssgproject.content_rule_require_singleuser_auth',    # Access managed via Cloud Console/IAM
  'xccdf_org.ssgproject.content_rule_uefi_password',              # Bootloader passwords not applicable in Cloud
  'xccdf_org.ssgproject.content_rule_selinux_state',              # Handled by runtime config management

  # Image Build / Initial Run Exceptions
  'xccdf_org.ssgproject.content_rule_aide_build_database',        # Fails until first AIDE init
  'xccdf_org.ssgproject.content_rule_aide_verify_audit_tools',
  'xccdf_org.ssgproject.content_rule_configure_strategy',         # Managed via custom cloud-init policies
  
  # Application Specific Requirements (Needed for this Image)
  'xccdf_org.ssgproject.content_rule_service_httpd_disabled',     # Apache is required
  'xccdf_org.ssgproject.content_rule_service_nginx_disabled'      # NGINX is required
] %}

# State to generate the XML tailoring file from the list above
oscap_tailoring_file:
  file.managed:
    - name: /tmp/oscap/oscap_tailoring.xml
    - contents: |
        <?xml version="1.0" encoding="UTF-8"?>
        <xccdf:Tailoring xmlns:xccdf="http://checklists.nist.gov/xccdf/1.2" id="xccdf_scap-adviser_tailoring_custom">
          <xccdf:benchmark href="/usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml"/>
          <xccdf:Profile id="xccdf_org.ssgproject.content_profile_cis_server_l1_custom" extends="xccdf_org.ssgproject.content_profile_cis_server_l1">
            <xccdf:title xml:lang="en-US">Customized CIS Profile</xccdf:title>
            {%- for rule in oscap_exceptions %}
            <xccdf:select idref="{{ rule }}" selected="false"/>
            {%- endfor %}
          </xccdf:Profile>
        </xccdf:Tailoring>
    - require:
      - file: oscap_scan

openscap_run_cis_l1:
  cmd.run:
    - name: |
        sudo oscap xccdf eval \
          --profile xccdf_org.ssgproject.content_profile_cis_server_l1 \
          --tailoring-file /tmp/oscap/oscap_tailoring.xml \
          --results /tmp/oscap/oscap_cis_l1_results.xml \
          --report /tmp/oscap/oscap_cis_l1_report.html \
          {{ ssg_file }} | tee /tmp/oscap/oscap_cis_l1_log.txt
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
      - openscap-scanner
      - scap-security-guide
