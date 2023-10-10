#########################################################################################
# This script will enforce CIS L1 controls mentioned in the following two jira.         #
# https://jira.cloudera.com/browse/CB-11455                                             #
# https://jira.cloudera.com/browse/CB-8896                                              #
#########################################################################################

{% set cloud_provider = salt['environ.get']('CLOUD_PROVIDER') %}
{% set os = salt['environ.get']('OS') %}

set_hardening_to_cis_server_l1:
  file.managed:
    - name: /log/hardening
    - contents:
      - "cis_server_l1"

#### CIS: Strengthen the ownership for job Scheduler
# https://jira.cloudera.com/browse/CB-8932
#Cron permission
Permission_etc/crontab:
  file.managed:
    - name: /etc/crontab
    - user: root
    - group: root
    - mode: 600
Permission_/etc/cron.hourly:
  file.directory:
    - name: /etc/cron.hourly
    - user: root
    - group: root
    - mode: 700
Permission_/etc/cron.daily:
  file.directory:
    - name: /etc/cron.daily
    - user: root
    - group: root
    - mode: 700
Permission_/etc/cron.weekly:
  file.directory:
    - name: /etc/cron.weekly
    - user: root
    - group: root
    - mode: 700
Permission_/etc/cron.monthly:
  file.directory:
    - name: /etc/cron.monthly
    - user: root
    - group: root
    - mode: 700
Permission_/etc/cron.d:
  file.directory:
    - name: /etc/cron.d
    - user: root
    - group: root
    - mode: 700
#Ensure cron is restricted to authorized users
Delete_cron.DENY:
  cmd.run:
    - name: rm /etc/cron.deny
    - onlyif: "test -f /etc/cron.deny"
Create_cron.ALLOW:
  cmd.run:
    - name: touch /etc/cron.allow
    - unless: test -f /etc/cron.allow
Permission_etc/cron.allow:
  file.managed:
    - name: /etc/cron.allow
    - user: root
    - group: root
    - mode: 600

####CIS: Strengthen the password policy
#https://jira.cloudera.com/browse/CB-8935
#Ensure password expiration is 180 Days (This setting should be reviewed as per organization policy)
PASS_MAX_DAYS:
  file.replace:
    - name: /etc/login.defs
    - pattern: '^\s*PASS_MAX_DAYS.*'
    - repl: PASS_MAX_DAYS 180
    - append_if_not_found: True
#Ensure minimum days between password changes is 7 or more
PASS_MIN_DAYS:
  file.replace:
    - name: /etc/login.defs
    - pattern: '^\s*PASS_MIN_DAYS.*'
    - repl: PASS_MIN_DAYS 1
    - append_if_not_found: True
#Ensure password expiration warning days is 7 or more
PASS_WARN_AGE:
  file.replace:
    - name: /etc/login.defs
    - pattern: '^\s*PASS_WARN_AGE.*'
    - repl: PASS_WARN_AGE 7
    - append_if_not_found: True
#Ensure inactive password lock is 30 days or less
INACTIVE:
  cmd.run:
    - name: useradd -D -f 30

#### CIS: Ensure access to the su command is restricted
#https://jira.cloudera.com/browse/CB-8929
wheel_group_add:
  file.replace:
    - name: /etc/group
    - pattern: '^wheel:x:10:.*'
{% if os == 'centos7' %}
    - repl: 'wheel:x:10:centos,cloudbreak,saltuser,root'
{% else %}
    - repl: 'wheel:x:10:cloudbreak,saltuser,root'
{% endif %}
    - append_if_not_found: True
sugroup_group:
  group.present:
    - name: sugroup
update_pam.d_su:
  file.replace:
    - name: /etc/pam.d/su
    - pattern: |
        ^#?auth\s*required\s*pam_wheel\.so.*
    - repl: |
        auth required pam_wheel.so use_uid group=sugroup
    - append_if_not_found: True

#Ensure SSH LoginGraceTime is set to one minute or less - sshd_config
sshd_harden_addressLoginGraceTime:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^LoginGraceTime.*"
    - repl: "LoginGraceTime 60"
    - append_if_not_found: True

# 235 is the max value for ClientAliveInterval allowed by Azure Marketplace,
sshd_harden_sshIdealTime_ClientAliveInterval:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^ClientAliveInterval.*"
    - repl: "ClientAliveInterval 180"
    - append_if_not_found: True

#2.2.1.2 Ensure chrony is configured
Chrony_config:
  file.replace:
    - name: /etc/sysconfig/chronyd
    - pattern: "^OPTIONS=.*"
    - repl: 'OPTIONS="-u chrony"'
    - append_if_not_found: True

#### CIS: Log configurations
# https://jira.cloudera.com/browse/CB-8928
/var/log_permission:
  cmd.run:
    - name: find /var/log -type f -exec chmod g-wx,o-rwx "{}" +

/var/log_default_group_permission:
  cmd.run:
    - name: setfacl -R -d -m g::r /var/log

/var/log_default_other_permission:
  cmd.run:
    - name: setfacl -R -d -m o::--- /var/log

#### CIS: Disable unused filesystems
#https://jira.cloudera.com/browse/CB-8897
{% set filesystems_to_disable = ['cramfs', 'freevxfs', 'jffs2', 'hfs', 'hfsplus', 'squashfs'] %}
{% if cloud_provider != 'Azure' %}
  # udf is required for Azure to mount cdrom - See CB-11012
  {% do filesystems_to_disable.append('udf') %}
{% endif %}
{% if cloud_provider != 'GCP' and not (cloud_provider == 'Azure' and os == 'redhat8')  %}
  # fat is required for gcp and azure rhel8 images
  {% do filesystems_to_disable.append('fat') %}
{% endif %}

create modrobe blacklist:
  cmd.run:
    - name: touch /etc/modprobe.d/salt_cis.conf
    - unless: test -f /etc/modprobe.d/salt_cis.conf

{% for fs in filesystems_to_disable %}

{{ fs }} disabled:
  file.replace:
      - name: /etc/modprobe.d/salt_cis.conf
      - pattern: "^install {{ fs }} /bin/true"
      - repl: install {{ fs }} /bin/true
      - append_if_not_found: True
  cmd.run:
      - name: modprobe -r {{ fs }}
      - onlyif: "lsmod | grep {{ fs }}"

{% endfor %}

remove_unnecessary_whitespaces_from_yum_repo_files:
  cmd.run:
    - name: find /etc/yum.repos.d -type f -exec sed -i 's/ = /=/g' {} \;
    - onlyif: ls -la /etc/yum.repos.d/
