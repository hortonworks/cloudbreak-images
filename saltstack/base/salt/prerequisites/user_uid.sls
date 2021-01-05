{% set ids = salt['grains.filter_by']({
    'amazon-ebs': {
        'cloudera_scm_user': '992',
        'cloudera_scm_group': '988',
    },
    'azure-arm': {
        'cloudera_scm_user': '991',
        'cloudera_scm_group': '987',
    },
    'googlecompute': {
        'cloudera_scm_user': '992',
        'cloudera_scm_group': '988',
    },
},
grain='builder_type',
default='amazon-ebs'
)%}

create_cloudera_scm_group:
  group.present:
    - name: cloudera-scm
    - gid: {{ ids.cloudera_scm_group }} 

create_cloudera_scm_user:
  user.present:
    - name: cloudera-scm
    - fullname: Cloudera Manager
    - shell: /sbin/nologin
    - home: /var/lib/cloudera-scm-server
    - createhome: False
    - uid: {{ ids.cloudera_scm_user }}
    - gid: {{ ids.cloudera_scm_group }}     
    - groups:
      - cloudera-scm
