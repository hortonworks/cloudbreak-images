FROM docker.io/centos:7.3.1611

ENV TERM linux

# Fix the default shell from dash to bash
# Do it one line. Otherwise, after doing rm, docker build cannot find a shell to
# run more RUN commands :)
RUN bash -c 'rm /bin/sh; ln -s /bin/bash /bin/sh'
RUN chsh -s /bin/bash

#################################################################################
# Systemd stuff
#################################################################################
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*;\
    rm -f /etc/systemd/system/*.wants/*;\
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*;\
    rm -f /lib/systemd/system/anaconda.target.wants/*;
#################################################################################

#################################################################################
# Setup yum repos
#################################################################################

# Disable fast-mirrors plugin and force everything through our internal repo
RUN sed -i -e 's/^enabled=1/enabled=0/g' /etc/yum/pluginconf.d/fastestmirror.conf

# Install epel repo files. epel-release has to go first before some of the other
# packages can be installed
RUN yum -y install epel-release

# BUG-68936 Fixing the image to use the HWX internal repos to avoid massive
# downloads due to cache-misses on the internal caching-proxy.
RUN rm -rf /etc/yum.repos.d/*
COPY files/hwx-internal.repo /etc/yum.repos.d/

# Give preference to our repos
RUN yum -y install yum-priorities
#################################################################################

#################################################################################
# Setup Ansible
#################################################################################
RUN mkdir -p /tmp/image-build-space/ansible
RUN yum install -y ansible

# Copy our file only after ansible is installed
COPY files/ansible/hosts.txt /etc/ansible/hosts
#################################################################################

# Wire-encryption tests need this module. Only specific version. Other versions
# beyond this, for e.g. 2.12.1 cause SSL related issues
RUN yum install -y python-pip && \
    pip install requests==2.11.1

#################################################################################
# Install all bits using ansible
#################################################################################
# Separately copy the layers to leverage docker caching
COPY files/ansible/basic-tools.yml /tmp/image-build-space/ansible/
RUN ansible-playbook -c local /tmp/image-build-space/ansible/basic-tools.yml

COPY files/ansible/networking-tools.yml /tmp/image-build-space/ansible/
RUN ansible-playbook -c local /tmp/image-build-space/ansible/networking-tools.yml

COPY files/ansible/hwx-internal-dependencies.yml /tmp/image-build-space/ansible/
RUN ansible-playbook -c local /tmp/image-build-space/ansible/hwx-internal-dependencies.yml

COPY files/ansible/dev-tools.yml /tmp/image-build-space/ansible/
RUN ansible-playbook -c local /tmp/image-build-space/ansible/dev-tools.yml
#################################################################################

RUN mkdir -p /tmp/image-build-space/image-prep-scripts

#################################################################################
# Setup access
#################################################################################
RUN mkdir -p /tmp/image-build-space/access

COPY files/access/* /tmp/image-build-space/access/

COPY files/pam/* /tmp/image-build-space/access/

COPY files/image-prep-scripts/setup-access.sh /tmp/image-build-space/image-prep-scripts
RUN /tmp/image-build-space/image-prep-scripts/setup-access.sh

COPY files/image-prep-scripts/hwx-internal-setup.sh /tmp/image-build-space/image-prep-scripts
RUN /tmp/image-build-space/image-prep-scripts/hwx-internal-setup.sh
#################################################################################

# install iproute explicitly on centos7, it's present by default in centos6, debian7
RUN yum -y install iproute

# highly insecure hack to  start systemd
RUN mkdir -p /bootstrap /bootstrap/logs

COPY files/image-prep-scripts/privileged-start-services-script.c /tmp/image-build-space/image-prep-scripts/

RUN gcc /tmp/image-build-space/image-prep-scripts/privileged-start-services-script.c -D COMMAND=\"/bootstrap/start-services-script.sh\" -o /bootstrap/start-systemd
RUN chgrp -v nobody /bootstrap/start-systemd
RUN chmod 4050 /bootstrap/start-systemd

ADD files/image-runtime-scripts/start-services-script.sh /bootstrap/

#################################################################################
# Operating system specific stuff
#################################################################################
COPY files/base-centos7.3-os-specific-build.sh /tmp/image-build-space/
RUN /tmp/image-build-space/base-centos7.3-os-specific-build.sh

ENV container docker

# Get rid "Unable to get valid context .." message
COPY files/autorelabel /.autorelabel

VOLUME [ "/sys/fs/cgroup" ]

CMD ["/bootstrap/start-systemd"]
# CMD ["/usr/sbin/init"]
