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

#1.1.24 Disable USB Storage
Disable_USB:
  file.replace:
    - name: /etc/modprobe.d/salt_cis.conf
    - pattern: '^install usb-storage /bin/true'
    - repl: install usb-storage /bin/true
    - append_if_not_found: True
Unload_usb:
  cmd.run:
    - name: rmmod usb-storage
    - onlyif: lsmod | grep usb-storage

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

#the value was kept as high as 1800, otherwise e2e test fails.
sshd_harden_sshIdealTime_ClientAliveInterval:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^ClientAliveInterval.*"
    - repl: "ClientAliveInterval 1800"
    - append_if_not_found: True
sshd_harden_sshIdealTime_ClientAliveCountMax:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^ClientAliveCountMax.*"
    - repl: "ClientAliveCountMax 3"
    - append_if_not_found: True

sshd_harden_ssh2:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^Protocol.*"
    - repl: "Protocol 2"
    - append_if_not_found: True

sshd_local_WarnBanner1:
  file.managed:
    - name: /etc/issue
    - contents: |
        Corporate computer security personnel monitor this system for security purposes to ensure it remains available to all users and to protect information in the system. By accessing this system, you are expressly consenting to these monitoring activities.
        Unauthorized attempts to defeat or circumvent security features, to use the system for other than intended purposes, to deny service to authorized users, to access, obtain, alter, damage, or destroy information, or otherwise to interfere with the system or its operation are prohibited. Evidence of such acts may be disclosed to law enforcement authorities and result in criminal prosecution under the Computer Fraud and Abuse Act of 1986 (Pub. L. 99-474) and the National Information Infrastructure Protection Act of 1996 (Pub. L. 104-294), (18 U.S.C. 1030), or other applicable criminal laws.
sshd_local_WarnBanner2:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^Banner.*"
    - repl: "Banner /etc/issue.net"
    - append_if_not_found: True

sshd_remote_WarnBanner:
  file.managed:
    - name: /etc/issue.net
    - contents: |
        Corporate computer security personnel monitor this system for security purposes to ensure it remains available to all users and to protect information in the system. By accessing this system, you are expressly consenting to these monitoring activities.
        Unauthorized attempts to defeat or circumvent security features, to use the system for other than intended purposes, to deny service to authorized users, to access, obtain, alter, damage, or destroy information, or otherwise to interfere with the system or its operation are prohibited. Evidence of such acts may be disclosed to law enforcement authorities and result in criminal prosecution under the Computer Fraud and Abuse Act of 1986 (Pub. L. 99-474) and the National Information Infrastructure Protection Act of 1996 (Pub. L. 104-294), (18 U.S.C. 1030), or other applicable criminal laws.
sshd_harden_ApprovedCiphers:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^Ciphers"
    - repl: "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr"
    - append_if_not_found: True

sshd_harden_ApprovedMACs:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^MACs"
    - repl: "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256"
    - append_if_not_found: True

sshd_Exchange_algorithms:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^KexAlgorithms .*"
    - repl: "KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256"
    - append_if_not_found: True

sshd_harden_LogLevel:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^LogLevel"
    - repl: "LogLevel INFO"
    - append_if_not_found: True
#5.2.21 Ensure SSH MaxStartups is configured
sshd_harden_MaxStartups:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^maxstartups .*"
    - repl: "maxstartups 10:30:60"
    - append_if_not_found: True

#### CIS: Sudo Configuration
#1.3.2 Ensure sudo commands use pty
sudo_pty:
  file.replace:
    - name: /etc/sudoers
    - pattern: "^Defaults use_pty"
    - repl: "Defaults use_pty"
    - append_if_not_found: True

#1.3.3 Ensure sudo log file exists
sudo_log:
  file.replace:
    - name: /etc/sudoers
    - pattern: "^Defaults logfile=.*"
    - repl: 'Defaults logfile="/var/log/sudo.log"'
    - append_if_not_found: True

#### CIS: Service hardening
#2.2.17 Ensure rsync is not installed or the rsyncd service is masked
mask_rsyncd:
  cmd.run:
    - name: sudo systemctl --now mask rsyncd

#### CIS: Ensure unnecessary services/softwareClients are removed
# https://jira.cloudera.com/browse/CB-8926

Ensure_X_Window_System_is_not_installed:
  cmd.run:
    - name: sudo yum remove -y xorg-x11-server*

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
/var/log_permission:
  cmd.run:
    - name: find /var/log -type f -exec chmod g-wx,o-rwx "{}" + -o -type d -exec chmod g-wx,o-rwx "{}" +
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
#Ensure IPv6 router advertisements are not accepted
net.ipv6.conf.all.accept_ra:
  sysctl.present:
    - value: 0
net.ipv6.conf.default.accept_ra:
  sysctl.present:
    - value: 0
#Ensure IPv6 redirects are not accepted
net.ipv6.conf.all.accept_redirects:
  sysctl.present:
    - value: 0
net.ipv6.conf.default.accept_redirects:
  sysctl.present:
    - value: 0
net.ipv6.route.flush:
  sysctl.present:
    - value: 1
#3.2.1 Ensure IP forwarding is disabled
net.ipv4.ip_forward:
  sysctl.present:
    - value: 0
#3.3.1 Ensure source routed packets are not accepted
net.ipv4.conf.all.accept_source_route:
  sysctl.present:
    - value: 0
net.ipv4.conf.default.accept_source_route:
  sysctl.present:
    - value: 0
#3.3.5 Ensure broadcast ICMP requests are ignored
net.ipv4.icmp_echo_ignore_broadcasts:
  sysctl.present:
    - value: 1
#3.3.6 Ensure bogus ICMP responses are ignored
net.ipv4.icmp_ignore_bogus_error_responses:
  sysctl.present:
    - value: 1
#3.3.7 Ensure Reverse Path Filtering is enabled
net.ipv4.conf.all.rp_filter:
  sysctl.present:
    - value: 1
net.ipv4.conf.default.rp_filter:
  sysctl.present:
    - value: 1
#3.3.8 Ensure TCP SYN Cookies is enabled
net.ipv4.tcp_syncookies:
  sysctl.present:
    - value: 1
net.ipv4.route.flush:
  sysctl.present:
    - value: 1
#2.2.1.2 Ensure chrony is configured
Chrony_config:
  file.replace:
    - name: /etc/sysconfig/chronyd
    - pattern: "^OPTIONS=.*"
    - repl: 'OPTIONS="-u chrony"'
    - append_if_not_found: True

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
#3.6.3 Ensure loopback traffic is configured
Loopback_Interface_input1:
  cmd.run:
    - name: sudo iptables -A INPUT -i lo -j ACCEPT
Loopback_Interface_output:
  cmd.run:
    - name: sudo iptables -A OUTPUT -o lo -j ACCEPT
Loopback_Interface_input2:
  cmd.run:
    - name: sudo iptables -A INPUT -s 127.0.0.0/8 -j DROP
Loopback_save_config:
  cmd.run:
    - name: sudo service iptables save
Iptables_enable_onboot:
  cmd.run:
    - name: sudo systemctl enable iptables

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
    - name: /etc/cron.allow
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
    - name: /etc/at.allow
    - user: root
    - group: root
    - mode: 600

#1.1.21 Ensure sticky bit is set on all world-writable directories
StickyBit_WW:
  cmd.run:
    - name: sudo df --local -P | awk '{if (NR!=1) print $6}' | xargs -I '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null | xargs -I '{}' chmod a+t '{}'
#1.2.3 Ensure gpgcheck is globally activated
gpgcheck_clustermanager:
  cmd.run:
    - name: sudo sed -i 's|gpgcheck=0|gpgcheck=1|g' /etc/yum.repos.d/clustermanager.repo
#1.6.3 Ensure address space layout randomization (ASLR) is enabled
Enable_ASLR:
  file.replace:
    - name: /etc/sysctl.conf
    - pattern: '^kernel.randomize_va_space =.*'
    - repl: 'kernel.randomize_va_space = 2'
    - append_if_not_found: True
#6.2.6 Ensure users home directories permissions are 750 or more restrictive
Home_directory_permission:
  cmd.run:
    - name: find /home -mindepth 1 -maxdepth 1 -type d -exec chmod -v 0750 {} \;

#### CIS - Filesystem Configurations
#Ensure noexec option set on /dev/shm partition
dev_shm_noexec:
  file.replace:
    - name: /etc/fstab
    - pattern: '^tmpfs\s*\/dev\/shm\s*.*'
    - repl: 'tmpfs                   /dev/shm                tmpfs   defaults,nodev,nosuid,noexec        0 0'
    - append_if_not_found: True
dev_shm_remount:
  cmd.run:
    - name: 'sudo mount -o remount,noexec,nodev,nosuid /dev/shm'

#### CIS - Strengthen the System file permissions
# https://jira.cloudera.com/browse/CB-8934
#Ensure no world writable files exist
Find_Delete_WWFiles:
  cmd.run:
    - name: 'sudo find / -xdev -type f -perm -0002 -exec chmod o-w {} \;'
#Ensure no unowned files or directories exist
Fine_own_unowned_files:
  cmd.run:
    - name: 'sudo find / -xdev -nouser -exec chown root:root {} \;'

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

####CIS: Strengthening the PAM
#https://jira.cloudera.com/browse/CB-8936
#Ensure password creation requirements are configured
Minlength:
  file.replace:
    - name: /etc/security/pwquality.conf
    - pattern: "^minlen = 14.*"
    - repl: minlen = 14
    - append_if_not_found: True
minclass:
  file.replace:
    - name: /etc/security/pwquality.conf
    - pattern: "^minclass.*"
    - repl: minclass = 4
    - append_if_not_found: True
etc/pam.d/system-auth:
  file.managed:
    - name: /etc/pam.d/system-auth
    - makedirs: True
    - source: salt://{{ slspath }}/etc/pam.d/system-auth
    - user: root
    - group: root
etc/pam.d/password-auth:
  file.managed:
    - name: /etc/pam.d/password-auth
    - makedirs: True
    - source: salt://{{ slspath }}/etc/pam.d/password-auth
    - user: root
    - group: root

#Ensure default user umask is 027 or more restrictive
Umask027:
  cmd.run:
    - name: "for TEMPLATE in 'bashrc' 'profile'; do sed -i 's|umask 002|umask 027|g' /etc/${TEMPLATE}; done"
Umask077:
  cmd.run:
    - name: "for TEMPLATE in 'bashrc' 'profile'; do sed -i 's|umask 022|umask 077|g' /etc/${TEMPLATE}; done"
#Ensure default user shell timeout is 900 seconds or less
TMOUT_profile:
  cmd.run:
    - name: printf "readonly TMOUT=900 ; export TMOUT" >> /etc/profile
TMOUT_bashrc:
  cmd.run:
    - name: printf "readonly TMOUT=900 ; export TMOUT" >> /etc/bashrc

#### CIS: Ensure access to the su command is restricted
#https://jira.cloudera.com/browse/CB-8929
wheel_group_add:
  file.replace:
    - name: /etc/group
    - pattern: '^wheel:x:10:.*'
    - repl: 'wheel:x:10:centos,cloudbreak,saltuser,root'
    - append_if_not_found: True
update_pam.d_su:
  file.replace:
    - name: /etc/pam.d/su
    - pattern: '^auth\s*required\s*pam_wheel\.so.*'
    - repl: 'auth required pam_wheel.so use_uid'
    - append_if_not_found: True

{% endif %}
