FROM docker-sandbox.infra.cloudera.com/cloudbreak/base-centos7.6:0.1.0.0-88
ARG PRE_WARM_PARCELS
ARG PRE_WARM_CSD

ENV PRE_WARM_PARCELS=${PRE_WARM_PARCELS}
ENV PRE_WARM_CSD=${PRE_WARM_CSD}

#we build logic on the existance of this directory, please DO NOT REMOVE
RUN mkdir /yarn-private
RUN touch /yarn-private/logs

# Haproxy setup.
RUN yum install haproxy -y
ADD docker/yarn-loadbalancer/configuration-files/haproxy.cfg /tmp/

# Startup script.
ADD docker/yarn-loadbalancer/image-runtime-scripts/start-services-script.sh /bootstrap/
RUN chmod +x /bootstrap/start-services-script.sh

#################################################################################

VOLUME [ "/sys/fs/cgroup" ]

ENTRYPOINT ["/bootstrap/start-systemd"]
CMD []
