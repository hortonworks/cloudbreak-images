#!/bin/bash

# Common code for centos 7.2, 7.3 and 7.4

# Fix dbus starting
mkdir -p /etc/selinux/targeted/contexts/
echo '<busconfig><selinux></selinux></busconfig>' > /etc/selinux/targeted/contexts/dbus_contexts

#################################################################################
# Install stuff needed by Ambari
#################################################################################

# This line is the output of 2 days of debugging. QE Ambari setup needs this to
# start firefox, but doesn't install it. Debugging was hard as Run-tests job later
# installs it erasing the evidence. This mysteriously works when openJDK7
# is involved instead of OracleJDK8.
yum -y install alsa-lib libXrender.x86_64 dbus-glib gtk2

# Extra stuff needed for installing python modules
yum -y install libffi-devel openssl-devel

# packages needed for Mysql / MariaDB installs
yum -y install initscripts

# QE-10584: By default, the docker CentOS7 containers are built using yum's nodocs
# option, which helps reduce the size of the image, but it affects Ambari oozie
# installation
sed -i -e 's/tsflags=nodocs/#tsflags=nodocs/g' /etc/yum.conf

# BUG-68561: Changing keyring configuration in krb5.conf as otherwise kerberos
# tools suddenly started failing due to UID clashes in the keyring.
sed -i -e 's#default_ccache_name = KEYRING:persistent:%{uid}#default_ccache_name = /tmp/krb5cc_%{uid}#g' /etc/krb5.conf

yum clean all

localedef -i en_US -f UTF-8 en_US.UTF-8
#################################################################################
