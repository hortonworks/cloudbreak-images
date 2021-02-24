#### CIS: Disable unused filesystems
#https://jira.cloudera.com/browse/CB-8897

{% if pillar['OS'] == 'centos7' %}

# fat is required
# udf is required for Azure to mount cdrom - See CB-11012
{% set filesystems = ['cramfs', 'freevxfs', 'jffs2', 'hfs', 'hfsplus', 'squashfs'] %}

{% for fs in filesystems %}

{{ fs }} create modrobe blacklist:
    cmd.run:
        - name: touch /etc/modprobe.d/salt_cis.conf
        - unless: test -f /etc/modprobe.d/salt_cis.conf

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

#### CIS: Harden SSH Configurations
#https://jira.cloudera.com/browse/CB-8933

sshd_harden_addressX11:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^X11Forwarding.*"
    - repl: "X11Forwarding no"
    - append_if_not_found: True

sshd_harden_addressMaxAuthTries:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^MaxAuthTries.*"
    - repl: "MaxAuthTries 4"
    - append_if_not_found: True

sshd_harden_addressIgnoreRhosts:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^IgnoreRhosts.*"
    - repl: "IgnoreRhosts yes"
    - append_if_not_found: True

sshd_harden_addressHostbasedAuth:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^HostbasedAuthentication.*"
    - repl: "HostbasedAuthentication no"
    - append_if_not_found: True

sshd_harden_addressEmptyPass:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^PermitEmptyPasswords.*"
    - repl: "PermitEmptyPasswords no"
    - append_if_not_found: True

sshd_harden_addressUserEnvPermit:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^PermitUserEnvironment.*"
    - repl: "PermitUserEnvironment no"
    - append_if_not_found: True

sshd_harden_addressLoginGraceTime:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^LoginGraceTime.*"
    - repl: "LoginGraceTime 60"
    - append_if_not_found: True

# Broken in e2e tests - see CB-8933 / CB-10728
#sshd_harden_sshIdealTime:
#  file.replace:
#    - name: /etc/ssh/sshd_config
#    - pattern: "^ClientAliveInterval.*"
#    - repl: "ClientAliveInterval 600 ClientAliveCountMax 0"
#    - append_if_not_found: True

sshd_harden_ssh2:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^Protocol.*"
    - repl: "Protocol 2"
    - append_if_not_found: True

sshd_harden_WarnBanner1:
  file.managed:
    - name: /etc/issue
    - contents: |
        Corporate computer security personnel monitor this system for security purposes to ensure it remains available to all users and to protect information in the system. By accessing this system, you are expressly consenting to these monitoring activities.
        Unauthorized attempts to defeat or circumvent security features, to use the system for other than intended purposes, to deny service to authorized users, to access, obtain, alter, damage, or destroy information, or otherwise to interfere with the system or its operation are prohibited. Evidence of such acts may be disclosed to law enforcement authorities and result in criminal prosecution under the Computer Fraud and Abuse Act of 1986 (Pub. L. 99-474) and the National Information Infrastructure Protection Act of 1996 (Pub. L. 104-294), (18 U.S.C. 1030), or other applicable criminal laws.
        
sshd_harden_WarnBanner2:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^Banner.*"
    - repl: "Banner /etc/issue"
    - append_if_not_found: True

sshd_harden_ApprovedCiphers:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^Ciphers"
    - repl: "Ciphers aes256-ctr,aes192-ctr,aes128-ctr"
    - append_if_not_found: True

sshd_harden_ApprovedMACs:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^MACs"
    - repl: "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com"
    - append_if_not_found: True

sshd_harden_LogLevel:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^LogLevel"
    - repl: "LogLevel INFO"
    - append_if_not_found: True

#### CIS: Ensure unnecessary services/softwareClients are removed
# https://jira.cloudera.com/browse/CB-8926

Ensure_X_Window_System_is_not_installed:
  cmd.run:
    - name: yum remove xorg-x11*

#### CIS: Ensure core dumps are restricted
# https://jira.cloudera.com/browse/CB-8925
#Restrict_Core_dumps_part1:
Create_limits.conf:
  cmd.run:
    - name: touch /etc/security/limits.conf
    - unless: test -f /etc/security/limits.conf
Update_limits.conf:
  file.replace:
    - name: /etc/security/limits.conf
    - pattern: '\* hard core 0'
    - repl: '* hard core 0'
    - append_if_not_found: True
#Restrict_Core_dumps_part2:
Create_sysctl.conf:
  cmd.run:
    - name: touch /etc/sysctl.conf
    - unless: test -f /etc/sysctl.conf
Update_sysctl.conf:
  file.replace:
    - name: /etc/sysctl.conf
    - pattern: "fs.suid_dumpable = 0"
    - repl: "fs.suid_dumpable = 0"
    - append_if_not_found: True
Disable_dump:  
  cmd.run:
    - name: sysctl -w fs.suid_dumpable=0

#### CIS: Log configurations
# https://jira.cloudera.com/browse/CB-8928
Logfile_permission:
  cmd.run:
    - name: find -L /var/log -type f -exec chmod g-wx,o-rwx {} +

#### CIS: Network Configurations
# https://jira.cloudera.com/browse/CB-8927
#3.1.2_Disabling_sending_packet_redirect:
Update_sysctl1:
  file.replace:
    - name: /etc/sysctl.conf
    - pattern: "^net.ipv4.conf.all.send_redirects = 0.*"
    - repl: "net.ipv4.conf.all.send_redirects = 0"
    - append_if_not_found: True      
Update_sysctl2:
  file.replace:
    - name: /etc/sysctl.conf
    - pattern: "^net.ipv4.conf.default.send_redirects = 0.*"
    - repl: "net.ipv4.conf.default.send_redirects = 0"
    - append_if_not_found: True
Execute1:
  cmd.run:
    - name: sysctl -w net.ipv4.conf.all.send_redirects=0
Execute2:
  cmd.run:
    - name: sysctl -w net.ipv4.conf.default.send_redirects=0
Execute3:
  cmd.run:
    - name: sysctl -w net.ipv4.route.flush=1
#3.2.2_Ensure_ICMP_redirects_are_not_accepted
Update_sysctl3:
  file.replace:
    - name: /etc/sysctl.conf
    - pattern: "^net.ipv4.conf.all.accept_redirects = 0.*"
    - repl: "net.ipv4.conf.all.accept_redirects = 0"
    - append_if_not_found: True
Update_sysctl4:
  file.replace:
    - name: /etc/sysctl.conf
    - pattern: "^net.ipv4.conf.default.accept_redirects = 0.*"
    - repl: "net.ipv4.conf.default.accept_redirects = 0"
    - append_if_not_found: True
Execute4:
  cmd.run:
    - name: sysctl -w net.ipv4.conf.all.accept_redirects=0
Execute5:
  cmd.run:
    - name: sysctl -w net.ipv4.conf.default.accept_redirects=0
Execute6:
  cmd.run:
    - name: sysctl -w net.ipv4.route.flush=1
#3.2.3_Ensure_Secure_ICMP_redirects_are_not_accepted
Update_sysctl5:
  file.replace:
    - name: /etc/sysctl.conf
    - pattern: "^net.ipv4.conf.all.secure_redirects = 0.*"
    - repl: "net.ipv4.conf.all.secure_redirects = 0"
    - append_if_not_found: True
Update_sysctl6:
  file.replace:
    - name: /etc/sysctl.conf
    - pattern: "^net.ipv4.conf.default.secure_redirects = 0.*"
    - repl: "net.ipv4.conf.default.secure_redirects = 0"
    - append_if_not_found: True
Execute7:
  cmd.run:
    - name: sysctl -w net.ipv4.conf.all.secure_redirects=0
Execute8:
  cmd.run:
    - name: sysctl -w net.ipv4.conf.default.secure_redirects=0
Execute9:
  cmd.run:
    - name: sysctl -w net.ipv4.route.flush=1
#3.2.4_Ensure_suspicious_packets_are_logged
Update_sysctl7:
  file.replace:
    - name: /etc/sysctl.conf
    - pattern: "^net.ipv4.conf.all.log_martians = 1.*"
    - repl: "net.ipv4.conf.all.log_martians = 1"
    - append_if_not_found: True
Update_sysctl8:
  file.replace:
    - name: /etc/sysctl.conf
    - pattern: "^net.ipv4.conf.default.log_martians = 1.*"
    - repl: "net.ipv4.conf.default.log_martians = 1"
    - append_if_not_found: True
Execute10:
  cmd.run:
    - name: sysctl -w net.ipv4.conf.all.log_martians=1
Execute11:
  cmd.run:
    - name: sysctl -w net.ipv4.conf.default.log_martians=1
Execute12:
  cmd.run:
    - name: sysctl -w net.ipv4.route.flush=1
#3.5.1-4_Ensure_DCCP/SCTP/RDS/TIPC are disabled
Ensure DCCP is disabled:
  file.replace:
    - name: /etc/modprobe.d/salt_cis.conf
    - pattern: "^install dccp /bin/true"
    - repl: install dccp /bin/true
    - append_if_not_found: True
Ensure SCTP is disabled:
  file.replace:
    - name: /etc/modprobe.d/salt_cis.conf
    - pattern: "^install sctp /bin/true"
    - repl: install sctp /bin/true
    - append_if_not_found: True
Ensure RDS is disabled:
  file.replace:
    - name: /etc/modprobe.d/salt_cis.conf
    - pattern: "^install rds /bin/true"
    - repl: install rds /bin/true
    - append_if_not_found: True
Ensure TIPC is disabled:
  file.replace:
    - name: /etc/modprobe.d/salt_cis.conf
    - pattern: "^install tipc /bin/true"
    - repl: install tipc /bin/true
    - append_if_not_found: True
#Ensure loopback traffic is configured
Loopback_Interface_input1:
  iptables.append:
    - chain: INPUT
    - in-interface: lo
    - jump: ACCEPT
Loopback_Interface_output:
  iptables.append:
    - chain: OUTPUT
    - out-interface: lo
    - jump: ACCEPT
Loopback_Interface_input1:
  iptables.append:
    - chain: INPUT
    - source: 127.0.0.0/8
    - jump: DROP


#### CIS: Enable filesystem Integrity Checking
# https://jira.cloudera.com/browse/CB-8919
packages_install_aide:
  pkg.installed:
    - name: aide
Initialize_aide:
  cmd.run:
    - name: aide --init
AIDE_db_setup:
  cmd.run:
    - name: mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
    - unless: 'test -f /var/lib/aide/aide.db.gz'
    - require:
      - pkg: aide
#1.3.2 Ensure filesystem integrity is regularly checked
Create_crontab:
  cmd.run:
    - name: touch /etc/crontab
    - unless: test -f /etc/crontab
update_aide_cronjob:
  file.replace:
    - name: /etc/crontab
    - pattern: '^\d.*\/usr\/sbin\/aide.*'
    - repl: '0 5 * * * /usr/sbin/aide --check'
    - append_if_not_found: True

#### CIS: Secure the Bootloader
# https://jira.cloudera.com/browse/CB-8920
# Ensure permissions on bootloader config are configured
Grub.cfg_permission:
  cmd.run:
    - name: chmod og-rwx /boot/grub2/grub.cfg

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
    - name: etc/cron.allow
    - user: root
    - group: root
    - mode: 600
#Ensure at is restricted to authorized users
Delete_at.DENY:
  cmd.run:
    - name: rm /etc/at.deny
    - onlyif: "ls /etc/at.deny"
Create_at.ALLOW:
  cmd.run:
    - name: touch /etc/at.allow
    - unless: test -f /etc/at.allow
Permission_etc/at.allow:
  file.managed:
    - name: etc/at.allow
    - user: root
    - group: root
    - mode: 600

#### CIS - Strengthen the System file permissions
# https://jira.cloudera.com/browse/CB-8934
#Ensure no world writable files exist
Find_Delete_WWFiles:
  cmd.run:
    - name: find / -xdev -type f -perm -0002 -exec chmod o-w {} \;
#Ensure no unowned files or directories exist
Fine_own_unowned_files:
  cmd.run:
    - name: find / -xdev -nouser -exec chown root:root {} \;

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
#Ensure inactive password lock is 30 days or less
INACTIVE:
  cmd.run:
    - name: useradd -D -f 30


{% endif %}
