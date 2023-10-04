/root/.ssh/authorized_keys:
  file.absent

/home/ec2-user/.ssh/authorized_keys:
  file.absent

/home/centos/.ssh/authorized_keys:
  file.absent

{% if not salt['file.directory_exists']('/vagrant') %}
/home/{{ pillar['os_user'] }}/.ssh/authorized_keys:
  file.absent
{% endif %}
