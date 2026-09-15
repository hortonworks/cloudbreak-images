{% set ids = {
  'cloudera_scm_user': '992',
  'cloudera_scm_group': '988',
} %}

{% if salt['environ.get']('CLOUD_PROVIDER') == 'Azure' and pillar['OS'] == 'redhat9' %}

# libstoragemgmt has the needed uid for cloudera-scm so it has to be removed
remove_libstoragemgmt:
  pkg.removed:
    - name: libstoragemgmt

remove_libstoragemgmt_user:
  user.absent:
    - name: libstoragemgmt

{% set ids = {
  'cloudera_scm_user': '991',
  'cloudera_scm_group': '987',
} %}

{% endif  %}

show_passwd:
  cmd.run:
    - name: |
        echo Contents of /etc/passwd before remapping...; cat /etc/passwd

list_original:
  cmd.run:
    - name: |
        touch /tmp/remap-original-resources.txt
        find / -ignore_readdir_race -not -path "/proc/*" -group {{ ids.cloudera_scm_group }} -exec printf "%s\n" {} \; >>/tmp/remap-original-resources.txt
        find / -ignore_readdir_race -not -path "/proc/*" -user {{ ids.cloudera_scm_user }} -exec printf "%s\n" {} \; >>/tmp/remap-original-resources.txt
        echo Original resources with GID/UID: {{ ids.cloudera_scm_group }}/{{ ids.cloudera_scm_user }}; cat /tmp/remap-original-resources.txt | sort | uniq

remap_gid:
  cmd.run:
    - name: |
        REMAPPED_GRP=$(getent group {{ ids.cloudera_scm_group }} | cut -d: -f1); groupmod -g 10001 $REMAPPED_GRP; find / -ignore_readdir_race -not -path "/proc/*" -group {{ ids.cloudera_scm_group }} -exec chgrp -h $REMAPPED_GRP {} \;
    - onlyif: getent group {{ ids.cloudera_scm_group }}

remap_uid:
  cmd.run:
    - name: |
        REMAPPED_USER=$(getent passwd {{ ids.cloudera_scm_user }} | cut -d: -f1); usermod -u 10001 $REMAPPED_USER; find / -ignore_readdir_race -not -path "/proc/*" -user {{ ids.cloudera_scm_user }} -exec chown -h $REMAPPED_USER {} \;
    - onlyif: getent passwd {{ ids.cloudera_scm_user }}

show_passwd_after_remapping:
  cmd.run:
    - name: |
        echo Contents of /etc/passwd after remapping...; cat /etc/passwd

list_updated:
  cmd.run:
    - name: |
        touch /tmp/remap-remapped-resources.txt
        find / -ignore_readdir_race -not -path "/proc/*" -group 10001 -exec printf "%s\n" {} \; >>/tmp/remap-remapped-resources.txt
        find / -ignore_readdir_race -not -path "/proc/*" -user 10001 -exec printf "%s\n" {} \; >>/tmp/remap-remapped-resources.txt
        echo Updated resources with new UID/GID:; cat /tmp/remap-remapped-resources.txt | sort | uniq

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
