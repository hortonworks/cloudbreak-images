remove_duplicates_from_yum_conf:
  cmd.run:
    - name: uniq /etc/yum.conf > /tmp/yum.conf && mv -f /tmp/yum.conf /etc/yum.conf && chmod 644 /etc/yum.conf && chown root:root /etc/yum.conf
