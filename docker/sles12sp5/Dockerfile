FROM registry.eng.hortonworks.com/hortonworks/base-sles12sp5:0.1.0.0-104

RUN zypper install -y SUSEConnect

# Need this for some dependencies, otherwise cloud-init will not install
# python-pyrsistent package is not available from simple repos
#RUN zypper ar -f -c http://download.opensuse.org/tumbleweed/repo/oss repo-oss && \
RUN zypper ar -f -c http://download.opensuse.org/distribution/leap/15.1/repo/oss/ repo-oss && \
zypper --gpg-auto-import-keys refresh && \
zypper install -y python-pyrsistent && \
zypper rr repo-oss

ARG SALT_VERSION
ARG SALT_PATH
ARG PYZMQ_VERSION
ARG PYTHON_APT_VERSION
ARG TRACE
ARG OS
ARG OS_TYPE
ARG JAVA_VERSION
ARG PRE_WARM_PARCELS
ARG PRE_WARM_CSD
ARG SLES_REGISTRATION_CODE

ENV SYSTEMCTL_REPLACEMENT=https://raw.githubusercontent.com/hortonworks/docker-systemctl-replacement/3a885817b377f0307bd03d82323fa5749136de8f/files/docker/systemctl.py
ENV PRE_WARM_PARCELS=${PRE_WARM_PARCELS}
ENV PRE_WARM_CSD=${PRE_WARM_CSD}

#################################################################################
# Install Cloudbreak dependencies
#################################################################################
# Use docker-systemctl-replacement during SaltStack provisioning:
# `systemctl start xyz` commands are executed during highstate, which is not supported
# by systemd. docker-systemctl-replacement overcomes this limitation.

# Need to explicitly call yum update before linking systemctl-replacement to avoid
# the later update (executed through Salt recipe) overwriting our fix.
# RUN yum -y update



RUN mkdir /etc/salt
COPY /saltstack /tmp/saltstack
COPY /repos /tmp/repos
COPY /scripts/salt-install.sh /tmp/saltstack/
COPY /scripts/salt-setup.sh /tmp/saltstack/
COPY /scripts/salt_requirements.txt /tmp/salt_requirements.txt

# Workaround problem caused by sytemd not being pid-1:
# Force the minions to use systemd on this host
RUN echo $'\n\
providers:\n\
  service: systemd\n'\
>>  /tmp/saltstack/config/minion

COPY docker/common/_grains/ /tmp/saltstack/base/salt/_grains/
COPY docker/common/_grains/ /tmp/saltstack/hortonworks/salt/_grains/

RUN /tmp/saltstack/salt-install.sh suse ${SALT_REPO}

ADD ${SYSTEMCTL_REPLACEMENT} /usr/bin
RUN chmod 755 /usr/bin/$(basename ${SYSTEMCTL_REPLACEMENT}) && \
    mv /usr/bin/systemctl /usr/bin/systemctl.orig && \
    ln -sf /usr/bin/systemctl.py /usr/bin/systemctl

ARG PARCELS_NAME
ARG STACK_REPOSITORY_VERSION
ARG STACK_TYPE
ARG CLUSTERMANAGER_VERSION
ARG CLUSTERMANAGER_BASEURL
ARG CLUSTERMANAGER_GPGKEY

ENV PARCELS_NAME=${PARCELS_NAME}
ENV STACK_REPOSITORY_VERSION=${STACK_REPOSITORY_VERSION}
ENV STACK_TYPE=${STACK_TYPE}
ENV CLUSTERMANAGER_VERSION=${CLUSTERMANAGER_VERSION}
ENV CLUSTERMANAGER_BASEURL=${CLUSTERMANAGER_BASEURL}
ENV CLUSTERMANAGER_GPGKEY=${CLUSTERMANAGER_GPGKEY}

#we build logic on the existance of this directory, please DO NOT REMOVE
RUN mkdir /yarn-private

RUN /tmp/saltstack/salt-setup.sh hortonworks
RUN rm -f /etc/salt/minion_id /etc/salt/pki/minion/minion.pem /etc/salt/pki/minion/minion.pub

# restore systemctl to system default
RUN ln -sf /usr/bin/systemctl.orig /usr/bin/systemctl

COPY docker/sles12sp5/start-systemd.sh /bootstrap/

COPY /docker/common/src /bootstrap/

RUN echo 'PATH=$PATH:/usr/lib/postgresql10/bin' >> /etc/bash.bashrc
RUN sed -i 's/#\?ENV_PATH.*/ENV_PATH       PATH=\/usr\/local\/bin:\/usr\/bin:\/bin:\/usr\/local\/games:\/usr\/games:\/usr\/lib\/postgresql10\/bin/' /etc/login.defs

#Temporary fix until salt fix not reach prod
RUN mkdir  /cloudbreak-salt-fix
RUN chmod 755 /cloudbreak-salt-fix
COPY docker/sles12sp5/cloudbreak-salt-fix/ /cloudbreak-salt-fix/
RUN chmod 755 -R /cloudbreak-salt-fix
RUN echo "* *    * * *   root    /cloudbreak-salt-fix/fix-cloudbreak-salt.sh" >> /etc/crontab

RUN gcc -Wall -DCOMMAND='"/bootstrap/start-systemd.sh"' -o /bootstrap/start-systemd /bootstrap/start-setuid.c

RUN groupmod -g 99 nogroup && \
    usermod -u 99 -g nogroup nobody
RUN chown root:nogroup /bootstrap/start-systemd && \
    chmod 4750 /bootstrap/start-systemd

#################################################################################

EXPOSE 22

RUN ls -d /etc/pam.d/* | xargs sed -i '/pam_nologin/d'
RUN echo -e "DefaultTasksMax=infinity" >> /etc/systemd/system.conf

ENTRYPOINT ["/bootstrap/start-systemd"]
CMD []
