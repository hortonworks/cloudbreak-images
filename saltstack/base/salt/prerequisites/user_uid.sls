{% set ids = {
  'cloudera_scm_user': '992',
  'cloudera_scm_group': '988',
} %}

pillar_items:
  cmd.run:
    - name: echo '{{ salt['pillar.items']() | json }}'

{% if salt['environ.get']('CLOUD_PROVIDER') == 'Azure' %}

{% set ids = {
  'cloudera_scm_user': '991',
  'cloudera_scm_group': '987',
} %}

{% endif %}

{% if pillar['OS'] == 'redhat8' %}
# sssd has the needed uid/gid for cloudera-scm so it has to be modified

change_sssd_ids:
  cmd.run:
    - name: |
        usermod -u 10001 salt
        groupmod -g 10001 salt
        find / -not -path "/proc/*" -user {{ ids.cloudera_scm_user }} -exec chown -h salt {} \;
        find / -not -path "/proc/*" -group {{ ids.cloudera_scm_group }}  -exec chgrp -h salt {} \;
{% endif %}

create_cloudera_scm_group:
  group.present:
    - name: cloudera-scm
    - gid: {{ ids.cloudera_scm_group }} 

create_cloudera_scm_user:
  user.present:
    - name: cloudera-scm
    - fullname: Cloudera Manager
    - shell: {{ salt['cmd.run']('which nologin') }}
    - home: /var/lib/cloudera-scm-server
    - createhome: False
    - uid: {{ ids.cloudera_scm_user }}
    - gid: {{ ids.cloudera_scm_group }}     
    - groups:
      - cloudera-scm
