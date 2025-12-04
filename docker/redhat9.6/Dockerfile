FROM docker-sandbox.infra.cloudera.com/ycloud-base/base-rhel9.6:0.1.0.0-1

ARG SALT_VERSION
ARG SALT_PATH
ARG SALTBOOT_VERSION
ARG SALTBOOT_HTTPS_ENABLED
ARG PYZMQ_VERSION
ARG PYTHON_APT_VERSION
ARG TRACE
ARG OS
ARG OS_TYPE
ARG ARCHITECTURE
ARG CLOUD_PROVIDER
ARG PRE_WARM_PARCELS
ARG PRE_WARM_CSD

# ENV SYSTEMCTL_REPLACEMENT=https://raw.githubusercontent.com/hortonworks/docker-systemctl-replacement/3a885817b377f0307bd03d82323fa5749136de8f/files/docker/systemctl.py
ENV SYSTEMCTL_REPLACEMENT=https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/refs/heads/master/files/docker/systemctl3.py
ENV PRE_WARM_PARCELS=${PRE_WARM_PARCELS}
ENV PRE_WARM_CSD=${PRE_WARM_CSD}

# Explicitly set language to avoid UnicodeEncodeError in pip installs
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

STOPSIGNAL SIGRTMIN+3

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
COPY /scripts/salt-final.sh /tmp/saltstack/
COPY /scripts/salt_${SALT_VERSION}_requirements.txt /tmp/salt_${SALT_VERSION}_requirements.txt

# Workaround problem caused by sytemd not being pid-1:
# Force the minions to use systemd on this host
RUN echo $'\n\
providers:\n\
  service: systemd_service\n'\
>>  /tmp/saltstack/config/minion

COPY docker/common/_grains/ /tmp/saltstack/base/salt/_grains/
COPY docker/common/_grains/ /tmp/saltstack/hortonworks/salt/_grains/

RUN /tmp/saltstack/salt-install.sh redhat

#ADD ${SYSTEMCTL_REPLACEMENT} /usr/bin
#RUN chmod 755 /usr/bin/$(basename ${SYSTEMCTL_REPLACEMENT}) && \
#    mv /usr/bin/systemctl /usr/bin/systemctl.orig && \
#    ln -sf /usr/bin/systemctl3.py /usr/bin/systemctl

ARG PARCELS_NAME
ARG STACK_REPOSITORY_VERSION
ARG STACK_TYPE
ARG CLUSTERMANAGER_VERSION
ARG CLUSTERMANAGER_BASEURL
ARG CLUSTERMANAGER_GPGKEY

ARG CUSTOM_IMAGE_TYPE
ARG DOCKER_REPOSITORY
ARG IMAGE_UUID
ARG DOCKER_IMAGE_NAME
ARG TAG
ARG IMAGE_NAME
ARG OS
ARG OS_TYPE
ARG ARCHITECTURE

ENV PARCELS_NAME=${PARCELS_NAME}
ENV STACK_REPOSITORY_VERSION=${STACK_REPOSITORY_VERSION}
ENV STACK_TYPE=${STACK_TYPE}
ENV CLUSTERMANAGER_VERSION=${CLUSTERMANAGER_VERSION}
ENV CLUSTERMANAGER_BASEURL=${CLUSTERMANAGER_BASEURL}
ENV CLUSTERMANAGER_GPGKEY=${CLUSTERMANAGER_GPGKEY}

ENV CUSTOM_IMAGE_TYPE=${CUSTOM_IMAGE_TYPE}
ENV DOCKER_REPOSITORY=${DOCKER_REPOSITORY}
ENV IMAGE_UUID=${IMAGE_UUID}
ENV DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME}
ENV TAG=${TAG}
ENV IMAGE_NAME=${IMAGE_NAME}
ENV OS=${OS}
ENV OS_TYPE=${OS_TYPE}
ENV ARCHITECTURE=${ARCHITECTURE}

ENV DEFAULT_JAVA_MAJOR_VERSION=17

ARG INCLUDE_FLUENT
ARG INCLUDE_CDP_TELEMETRY
ARG INCLUDE_METERING
ARG FREEIPA_PLUGIN_RPM_URL
ARG FREEIPA_LDAP_AGENT_RPM_URL
ARG JUMPGATE_AGENT_RPM_URL
ARG JUMPGATE_AGENT_VERSION
ARG JUMPGATE_AGENT_GBN

ENV INCLUDE_FLUENT="Yes"
ENV INCLUDE_CDP_TELEMETRY="Yes"
ENV INCLUDE_METERING="Yes"
ENV FREEIPA_PLUGIN_RPM_URL="https://archive.cloudera.com/cdp-freeipa-artifacts/cdp-hashed-pwd-1.1-b847.el7.x86_64.rpm"
ENV FREEIPA_LDAP_AGENT_RPM_URL="https://archive.cloudera.com/cdp-freeipa-artifacts/freeipa-ldap-agent-1.1.0.3-b525.x86_64.rpm"
ENV JUMPGATE_AGENT_RPM_URL="https://archive.cloudera.com/ccm/3.13.0/jumpgate-agent.rpm"
#we build logic on the existance of this directory, please DO NOT REMOVE
RUN mkdir /yarn-private

RUN /tmp/saltstack/salt-setup.sh hortonworks
RUN /tmp/saltstack/salt-final.sh
RUN rm -f /etc/salt/minion_id /etc/salt/pki/minion/minion.pem /etc/salt/pki/minion/minion.pub

# restore systemctl to system default
#RUN ln -sf /usr/bin/systemctl.orig /usr/bin/systemctl

ADD docker/redhat9.6/image-runtime-scripts/start-services-script.sh /bootstrap/

#################################################################################

VOLUME [ "/sys/fs/cgroup" ]

ENTRYPOINT ["/bootstrap/start-systemd"]
CMD []
