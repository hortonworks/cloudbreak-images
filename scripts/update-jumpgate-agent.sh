#! /bin/bash

# Example: JUMPGATE_AGENT_URL=https://archive.cloudera.com/ccm/3.16.0/jumpgate-agent.x86_64.rpm
: "${JUMPGATE_AGENT_URL:?}"

if [[ -z $JUMPGATE_AGENT_URL ]]; then
  exit 1
fi

# packer.sh

JUMPGATE_AGENT_VERSION=$(echo "$JUMPGATE_AGENT_URL" | sed -E 's|.*ccm/([0-9]+\.[0-9]+\.[0-9]+)/.*|\1|')
grep -n "JUMPGATE_AGENT_VERSION=" scripts/packer.sh
sed -i 's|\(^[[:space:]]*JUMPGATE_AGENT_VERSION=\)[0-9]\+\.[0-9]\+\.[0-9]\+|\1'"$JUMPGATE_AGENT_VERSION"'|' scripts/packer.sh
cat scripts/packer.sh | grep " JUMPGATE_AGENT_VERSION"

# Dockerfiles

sed -i 's|^\(ENV JUMPGATE_AGENT_RPM_URL=\)".*"|\1"'"$JUMPGATE_AGENT_URL"'"|' docker/redhat8.10/Dockerfile
cat docker/redhat8.10/Dockerfile | grep "ENV JUMPGATE_AGENT_RPM_URL"

sed -i 's|^\(ENV JUMPGATE_AGENT_RPM_URL=\)".*"|\1"'"$JUMPGATE_AGENT_URL"'"|' docker/redhat9.6/Dockerfile
cat docker/redhat9.6/Dockerfile | grep "ENV JUMPGATE_AGENT_RPM_URL"