# This is just a minimalist placeholder file that barely does anything besides forcing GPG checks on,
# so verify.sls passes.
#
# TODO: We'll need a proper implementation of enforcing CIS controls - see https://cloudera.atlassian.net/browse/CB-29427

gpgcheck_dump:
  cmd.run:
    - name: cat /etc/yum.repos.d/*

gpgcheck_enforce:
  cmd.run:
    - name: sed -i 's/^gpgcheck=0/gpgcheck=1/' /etc/yum.repos.d/*.repo