show_passwd:
  cmd.run:
    - name: |
        echo Contents of /etc/passwd before remapping...
        cat /etc/passwd

{% set ids = {
  'cloudera_scm_user': '992',
  'cloudera_scm_group': '988',
} %}

# OpenStack user remapping
##########################

{% if salt['environ.get']('CLOUD_PROVIDER') == 'Openstack' and pillar['OS'] == 'redhat9' %}
# flatpak has the needed uid for cloudera-scm so it has to be modified
change_flatpak_uid:
  cmd.run:
    - name: |
        usermod -u 10001 flatpak
        find / -ignore_readdir_race -not -path "/proc/*" -user {{ ids.cloudera_scm_user }} -exec chown -h flatpak {} \;
    - onlyif: id flatpak && [ "$(id -u flatpak)" -eq 992 ]

# AWS/AWSGov/GCP user remapping
###############################

{% elif (salt['environ.get']('CLOUD_PROVIDER') == 'AWS' or salt['environ.get']('CLOUD_PROVIDER') == 'AWS_GOV' or salt['environ.get']('CLOUD_PROVIDER') == 'GCP') and pillar['OS'] == 'redhat9' %}
remap_gid:
  cmd.run:
    - name: |
        REMAPPED_GRP=$(getent group {{ ids.cloudera_scm_group }} | cut -d: -f1); groupmod -g 10001 $REMAPPED_GRP; find / -not -path "/proc/*" -group {{ ids.cloudera_scm_group }} -exec chgrp -h $REMAPPED_GRP {} \;
    - onlyif: getent group {{ ids.cloudera_scm_group }}

remap_uid:
  cmd.run:
    - name: |
        REMAPPED_USER=$(cat /etc/passwd | grep {{ ids.cloudera_scm_user }}:{{ ids.cloudera_scm_user }} | cut -d: -f1); usermod -u 10001 $REMAPPED_USER; find / -not -path "/proc/*" -user {{ ids.cloudera_scm_user }} -exec chown -h $REMAPPED_USER {} \;
    - onlyif: id {{ ids.cloudera_scm_user }}

# YCLOUD user remapping
#######################

{% elif pillar['subtype'] == 'Docker' and pillar['OS'] == 'redhat9' %}
# saslauth has the needed uid/gid for cloudera-scm so it has to be modified, YCLOUD only
change_saslauth_uid:
  cmd.run:
    - name: |
        usermod -u 10002 saslauth
        find / -not -path "/proc/*" -user {{ ids.cloudera_scm_user }} -exec chown -h saslauth {} \;

# Azure user remapping
######################

{% elif salt['environ.get']('CLOUD_PROVIDER') == 'Azure' %}

{% if pillar['OS'] == 'redhat8' %}
# sssd has the needed uid/gid for cloudera-scm so it has to be modified
change_sssd_ids:
  cmd.run:
    - name: |
        usermod -u 10001 sssd
        groupmod -g 10001 sssd
        find / -not -path "/proc/*" -user {{ ids.cloudera_scm_user }} -exec chown -h sssd {} \;
        find / -not -path "/proc/*" -group {{ ids.cloudera_scm_group }}  -exec chgrp -h sssd {} \;

{% elif pillar['OS'] == 'redhat9' %}

{% set ids = {
  'cloudera_scm_user': '991',
  'cloudera_scm_group': '987',
} %}

# pipewire has the needed gid for cloudera-scm so it has to be modified
change_pipewire_ids:
  cmd.run:
    - name: |
        groupmod -g 10001 pipewire
        find / -not -path "/proc/*" -group {{ ids.cloudera_scm_group }} -exec chgrp -h pipewire {} \; ; exit 0

# libstoragemgmt has the needed uid for cloudera-scm so it has to be removed
remove_libstoragemgmt:
  pkg.removed:
    - name: libstoragemgmt

remove_libstoragemgmt_user:
  user.absent:
    - name: libstoragemgmt

{% endif %}
{% endif %}

show_passwd_after_remapping:
  cmd.run:
    - name: |
        echo Contents of /etc/passwd after remapping...
        cat /etc/passwd

# Cloudera SCM user / group creation
####################################

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
