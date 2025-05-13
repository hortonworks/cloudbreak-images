{% if pillar['OS'] == 'redhat8' or pillar['OS'] == 'redhat9' %}

remove_duplicates_from_yum_conf:
  cmd.run:
    - name: uniq /etc/yum.conf > /tmp/yum.conf && mv -f /tmp/yum.conf /etc/yum.conf && chmod 644 /etc/yum.conf && chown root:root /etc/yum.conf

{% elif pillar['OS'] == 'centos7' %}

# These (disabled by default) repositories fail CIS checks as they have gpgcheck=0, so let's remove them

remove_centos-sclo-sclo-testing_repository:
  pkgrepo.absent:
    - name: centos-sclo-sclo-testing

remove_centos-sclo-rh-testing_repository:
  pkgrepo.absent:
    - name: centos-sclo-rh-testing

{% endif %}
