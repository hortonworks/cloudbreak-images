FROM registry.eng.hortonworks.com/hortonworks/base-centos7.8:0.1.0.0-111

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



COPY /saltstack /tmp/saltstack
COPY /repos /tmp/repos
COPY /scripts/salt-install.sh /tmp/saltstack/
COPY /scripts/salt-setup.sh /tmp/saltstack/
COPY /scripts/salt_requirements.txt /tmp/salt_requirements.txt

# Workaround problem caused by sytemd not being pid-1:
# Force the minions to use systemd on this host
RUN echo $'\n\
providers:\n\
  service: systemd_service\n'\
>>  /tmp/saltstack/config/minion

COPY docker/common/_grains/ /tmp/saltstack/base/salt/_grains/
COPY docker/common/_grains/ /tmp/saltstack/hortonworks/salt/_grains/

RUN /tmp/saltstack/salt-install.sh centos ${SALT_REPO}

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

ADD docker/centos7.8/image-runtime-scripts/start-services-script.sh /bootstrap/

#################################################################################

VOLUME [ "/sys/fs/cgroup" ]

RUN chown root:nobody /bootstrap/start-systemd && \
    chmod 4750 /bootstrap/start-systemd && \
    chown root:nobody /bootstrap/start-services-script.sh && \
    chmod 4750 /bootstrap/start-services-script.sh

ENTRYPOINT ["/bootstrap/start-systemd"]
CMD []
