openscap_install:
  cmd.run:
    - name: yum install -y openscap-scanner

openscap_security_guide:
  cmd.run:
    - name: yum install -y scap-security-guide

openscap_run1:
  cmd.run:
    - name: ls /usr/share/xml/scap/ssg/content/
    
openscap_run2:
  cmd.run:
    - name: oscap info /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml

openscap_run_stig:
  cmd.run:
    - name: oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_stig --results /tmp/oscap-report.xml /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml | tee /tmp/cis/oscap_log.txt

openscap_log_chmod:
  cmd.run:
    - name: chmod 644 /tmp/cis/oscap_log.txt
