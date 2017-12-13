#!/bin/bash

#################################################################################
# Setup root account
#################################################################################

# setup authorized_keys for passphraseless access
mkdir -p /root/.ssh && cp /tmp/image-build-space/access/authorized_keys /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys
#################################################################################

#################################################################################
# Setup system access
#################################################################################

mkdir -p /var/run/sshd

# Setup ssh configuration
cp /tmp/image-build-space/access/sshd_config /etc/ssh/sshd_config && chmod 600 /etc/ssh/sshd_config

# sftp-server is in different locations in different OSes and our sshd_config above needs to point to the right place
if [ -e /usr/lib/ssh/sftp-server ]; then
  SFTP_BINARY="/usr/lib/ssh/sftp-server";
elif [ -e /usr/lib64/ssh/sftp-server ]; then
  SFTP_BINARY="/usr/lib64/ssh/sftp-server";
elif [ -e /usr/libexec/openssh/sftp-server ]; then
  SFTP_BINARY="/usr/libexec/openssh/sftp-server";
else
  SFTP_BINARY=`find /usr/ -type f -name sftp-server 2>/dev/null | head -1`;
fi
if [ x"${SFTP_BINARY}"x == "xx" ]; then
  echo 'No sftp binary!!'
else
  mkdir -p /usr/lib/openssh/ && ln -s ${SFTP_BINARY} /usr/lib/openssh/sftp-server && ls -l /usr/lib/openssh/sftp-server
fi

# Create PAM files to allow access as needed by system tests
for file in `ls /tmp/image-build-space/access/pam.d_*`
do
  pam_file=`basename $file| sed 's/pam.d_//'`
  cp $file /etc/pam.d/$pam_file && chmod 644 /etc/pam.d/$pam_file
done
#################################################################################
