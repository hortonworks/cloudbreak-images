/root/.ssh/authorized_keys:
  file.absent

/home/ec2-user/.ssh/authorized_keys:
  file.absent

{% if pillar['os_user'] != "vagrant" %}
/home/{{ pillar['os_user'] }}/.ssh/authorized_keys:
  file.absent
{% endif %}
