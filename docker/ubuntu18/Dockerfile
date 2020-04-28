FROM registry.eng.hortonworks.com/hortonworks/base-ubuntu18:0.1.0.0-105 as builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        systemd \
        gcc \
        libc6-dev

COPY /docker/common/src /src

RUN gcc -Wall -DCOMMAND='"/bootstrap/start-systemd.sh"' -o /systemd-wrapper /src/start-setuid.c


FROM registry.eng.hortonworks.com/hortonworks/base-ubuntu18:0.1.0.0-105

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

ENV PRE_WARM_PARCELS=${PRE_WARM_PARCELS}
ENV PRE_WARM_CSD=${PRE_WARM_CSD}

LABEL maintainer=Hortonworks

ARG SYSTEMCTL=https://raw.githubusercontent.com/hortonworks/docker-systemctl-replacement/3a885817b377f0307bd03d82323fa5749136de8f/files/docker/systemctl.py

ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux
ENV PS1 "[\u@cloudbreak \W]\$ "

# Set default shell to bash
SHELL ["/bin/bash", "-c"]

# Install packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        udev \
        gcc \
        libc6-dev \
        apt-transport-https \
        ca-certificates \
        cron \
        curl \
        gnupg2 \
        util-linux \
        iproute2 \
        python-minimal \
        ssh \
        sudo \
        virt-what \
        systemd && \
    rm -rf /var/lib/apt/lists/*

RUN add-apt-repository -y ppa:openjdk-r/ppa && apt-get update

# Replace systemctl during SaltStack provisioning
RUN dpkg-divert --add --rename /bin/systemctl && \
    curl -s -o /bin/systemctl $SYSTEMCTL && \
    chmod 755 /bin/systemctl


#we build logic on the existance of this directory, please DO NOT REMOVE
RUN mkdir /yarn-private

# SaltStack provisioning
COPY /saltstack/ /tmp/saltstack/
COPY /repos/     /tmp/repos/
COPY /scripts/   /tmp/scripts/
COPY /scripts/salt_requirements.txt /tmp/salt_requirements.txt
COPY docker/common/_grains/ /tmp/saltstack/base/salt/_grains/
COPY docker/common/_grains/ /tmp/saltstack/hortonworks/salt/_grains/
RUN printf '\n\nproviders:\n  service: systemd\n' >>/tmp/saltstack/config/minion
RUN /tmp/scripts/salt-install.sh ubuntu
RUN mkdir /etc/salt
RUN mkdir -p /etc/unbound/keys.d/

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

RUN /tmp/scripts/salt-setup.sh hortonworks
RUN rm -f /etc/salt/minion_id /etc/salt/pki/minion/minion.pem /etc/salt/pki/minion/minion.pub

# Fix SaltStack init autodiscovery
RUN printf '\n\nproviders:\n  service: systemd\n' >>/etc/salt/minion
COPY docker/common/_grains/ /srv/salt/_grains/

# Fix startup problems for Type=notify systemd services
COPY docker/common/systemd-fix.service /etc/systemd/system/
RUN systemctl enable systemd-fix

# Undo systemctl replacement
RUN rm /bin/systemctl && \
    dpkg-divert --remove --rename /bin/systemctl

# Fix ssh login and salt-api auth problems
RUN rm /lib/systemd/system/rmnologin.service

# Ycloud integration
RUN groupmod -g 99 nogroup && \
    usermod -u 99 -g nogroup nobody

#Temporary fix until salt fix not reach prod
RUN mkdir  /cloudbreak-salt-fix
RUN chmod 755 /cloudbreak-salt-fix
COPY docker/ubuntu18/cloudbreak-salt-fix/ /cloudbreak-salt-fix/
RUN chmod 755 -R /cloudbreak-salt-fix
RUN echo "* *    * * *   root    /cloudbreak-salt-fix/fix-cloudbreak-salt.sh" >> /etc/crontab

# CloudBreak expects /bootstrap/start-systemd as an entrypoint
COPY docker/ubuntu18/start-systemd.sh /bootstrap/start-systemd.sh
COPY --from=builder /systemd-wrapper /bootstrap/start-systemd
RUN chown root:nogroup -R /bootstrap/ && \
    chmod 4750 -R /bootstrap/

# Without these, postgresql initialization will not work, from cloudbreak Salts
RUN mkdir /var/lib/pgsql
RUN chmod 777 /var/lib/pgsql
RUN echo 'PATH=$PATH:/usr/lib/postgresql/9.5/bin' >> /etc/bash.bashrc
RUN sed -i 's/#\?ENV_PATH.*/ENV_PATH       PATH=\/usr\/local\/bin:\/usr\/bin:\/bin:\/usr\/local\/games:\/usr\/games:\/usr\/lib\/postgresql\/10\/bin/' /etc/login.defs

RUN systemctl enable ssh cron
RUN service ssh start

RUN ls -d /etc/pam.d/* | xargs sed -i '/pam_nologin/d'

RUN locale-gen en_US.UTF-8

COPY docker/ubuntu18/systemd/*.deb /tmp/
RUN dpkg -i /tmp/libsystemd0_237-3ubuntu10.40_amd64.deb
RUN dpkg -i /tmp/systemd_237-3ubuntu10.40_amd64.deb
RUN dpkg -i /tmp/libnss-systemd_237-3ubuntu10.40_amd64.deb
RUN dpkg -i /tmp/libpam-systemd_237-3ubuntu10.40_amd64.deb

EXPOSE 22

CMD ["/bootstrap/start-systemd"]
