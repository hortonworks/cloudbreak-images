openscap_install:
  cmd.run:
    - name: yum install -y openscap-scanner

openscap_security_guide:
  cmd.run:
    - name: yum install -y scap-security-guide
    
openscap_info:
  cmd.run:
    - name: oscap info /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml

openscap_run_stig:
  cmd.run:
    - name: sudo oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_stig --results /tmp/cis/oscap_stig_report.xml --report /tmp/cis/oscap_stig_report.html /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml | tee /tmp/cis/oscap_log.txt

openscap_log_and_report_chmod:
  cmd.run:
    - name: chmod 777 /tmp/cis/oscap_log.txt /tmp/cis/oscap_stig_report.xml /tmp/cis/oscap_stig_report.html

remove_security_guide:
   cmd.run:
    - name: yum remove -y scap-security-guide

remove_openscap:
   cmd.run:
    - name: yum remove -y openscap-scanner
