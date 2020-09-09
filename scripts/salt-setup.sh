#!/bin/bash

: ${DEBUG:=1}
: ${DRY_RUN:-1}

set -ex -o pipefail -o errexit

function prepare {
  sudo chown -R root:root /tmp/saltstack
  apply_amazonlinux_salt_patch
}

function copy_resources {
  local saltenv=${1}
  sudo mkdir -p /srv/salt/${saltenv} /srv/pillar/${saltenv}
  sudo cp -R /tmp/saltstack/${saltenv}/salt/* /srv/salt/${saltenv}
  if [ -d "/tmp/saltstack/${saltenv}/pillar" ]
  then
    sudo cp -R /tmp/saltstack/${saltenv}/pillar/* /srv/pillar/${saltenv}
  fi
}
  #Needed because of https://github.com/saltstack/salt/issues/47258
function apply_amazonlinux_salt_patch {
  if [ "${OS}" == "amazonlinux" ] && [ -f /tmp/saltstack/config/minion ] && ! grep -q "rh_service" /tmp/saltstack/config/minion ; then
    tee -a /tmp/saltstack/config/minion << EOF
providers:
  service: rh_service
EOF
  fi
}

function highstate {
  local saltenv=${1}
  copy_resources ${saltenv}
  ${SALT_PATH}/bin/salt-call --local state.highstate saltenv=${saltenv} --retcode-passthrough -l info --log-file=/tmp/salt-build-${saltenv}.log --log-file-level=info --config-dir=/tmp/saltstack/config
}

function apply_optional_states {
  echo "Running applying optional states: ${OPTIONAL_STATES}"

  if [ -n "${OPTIONAL_STATES}" ]
  then
    local saltenv="optional"
    copy_resources ${saltenv}
    ${SALT_PATH}/bin/salt-call --local state.sls ${OPTIONAL_STATES} saltenv=${saltenv} pillarenv=${saltenv} --retcode-passthrough -l info --log-file=/tmp/salt-build-${saltenv}.log --config-dir=/tmp/saltstack/config
  fi
}

# Appends any prewarmed roles to a (non-salt) file, one role per line. salt-bootstrap takes care of setting up these roles during node setup.
function add_single_role_for_cluster_salt {
  local role=${1}
  echo "${role}" >> /etc/salt/prewarmed_roles
}

function add_prewarmed_roles {
  if [ "${INCLUDE_FLUENT}" == "Yes" ]; then
    # Note: This will need to be changed if making changes to versions etc in the prewarmed image.
    local fluent_prewarmed=${FLUENT_PREWARM_TAG}
    echo "Adding ${fluent_prewarmed} to the list of roles for the final image"
    add_single_role_for_cluster_salt ${fluent_prewarmed}
  fi

  if  [ "${STACK_TYPE}" == "CDH" -a ! -z "${CLUSTERMANAGER_VERSION}" -a ! -z "${CLUSTERMANAGER_BASEURL}" -a ! -z "${CLUSTERMANAGER_GPGKEY}" -a ! -z "${STACK_VERSION}" -a ! -z "${STACK_BASEURL}" -a ! -z "${STACK_REPOID}" ]; then
    local prewarmed=${PREWARM_TAG}
    echo "Adding ${prewarmed} to the list of roles for the final image"
    add_single_role_for_cluster_salt ${prewarmed}
  fi

  if [ "${CUSTOM_IMAGE_TYPE}" == "hortonworks" ]; then
    local metering_prewarmed=${METERING_PREWARM_TAG}
    echo "Adding ${metering_prewarmed} to the list of roles for the final image"
    add_single_role_for_cluster_salt ${metering_prewarmed}
  fi
}

function delete_unnecessary_files() {
  # Salt (version as of this change: 3000.2) ends up taking a long time to load modules. vspere is an especially slow one taking 3 seconds.
  # Salt does not seem to allow skipping module load ('disable_modules' only disables module usage, not module loading)
  # So, deleting some modules which are not used, and tend to cause Exceptions / delays
  find /opt/salt_3000.2/lib/python3.6/site-packages/salt/modules/ -name "*lxd*" -exec rm -f {} \;
  find /opt/salt_3000.2/lib/python3.6/site-packages/salt/modules/ -name "*vsphere*" -exec rm -f {} \;
  find /opt/salt_3000.2/lib/python3.6/site-packages/salt/modules/ -name "*boto3_elasticsearch*" -exec rm -f {} \;
  find /opt/salt_3000.2/lib/python3.6/site-packages/salt/modules/ -name "*win_*" -exec rm -f {} \;
}

: ${CUSTOM_IMAGE_TYPE:=$1}

case ${CUSTOM_IMAGE_TYPE} in
  base|"")
    echo "Running highstate for Base.."
    prepare
    highstate "base"
  ;;
  freeipa)
    echo "Running highstate for FreeIPA.."
    prepare
    highstate "base"
    highstate "freeipa"
  ;;
  hortonworks)
    echo "Running highstate for Base and Hortonworks.."
    prepare
    highstate "base"
    highstate "hortonworks"
  ;;
  *)
    echo "Unsupported CUSTOM_IMAGE_TYPE:" ${CUSTOM_IMAGE_TYPE}
    exit 1
  ;;
esac

apply_optional_states

echo "Adding prewarmed roles for salt used in final image"
add_prewarmed_roles

echo "Running validation and cleanup"
highstate "final"

echo "Deleting some  unnecessary files ..."
delete_unnecessary_files
