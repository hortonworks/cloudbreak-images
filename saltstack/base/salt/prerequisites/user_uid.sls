create_cloudera_scm_group:
  group.present:
    - name: cloudera-scm

create_cloudera_scm_user:
  user.present:
    - name: cloudera-scm
    - fullname: Cloudera Manager
    - shell: {{ salt['cmd.run']('which nologin') }}
    - home: /var/lib/cloudera-scm-server
    - createhome: False
    - groups:
      - cloudera-scm
