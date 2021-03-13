#!/bin/bash
#6.2.6 Ensure users home directories permissions are 750 or more restrictive
/usr/bin/sudo /usr/bin/find /home -mindepth 1 -maxdepth 1 -type d -exec /usr/bin/chmod -v 0750 {} \;

#Ensure permissions on all logfiles are configured' >> /home/cloudbreak/cis.sh
/usr/bin/sudo /usr/bin/find /var/log -type f -exec /usr/bin/chmod g-wx,o-rwx "{}" + -o -type d -exec /usr/bin/chmod g-wx,o-rwx "{}" +

#1.1.22 Ensure sticky bit is set on all world-writable directories' >> /home/cloudbreak/cis.sh
/usr/bin/sudo /usr/bin/df --local -P | /usr/bin/awk '{if (NR!=1) print $6}' | xargs -I '{}' /usr/bin/find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null | xargs -I '{}' /usr/bin/chmod a+t '{}'
