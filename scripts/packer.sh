#!/bin/bash
set -ex -o pipefail -o errexit

function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

packer_in_container() {
  local dockerOpts=""
  local packerFile="packer.json"
  : "${PACKER_VERSION:="1.10.2"}"
  echo "Using Packer version $PACKER_VERSION"

  if [[ "$GCP_ACCOUNT_FILE" ]]; then
    dockerOpts="$dockerOpts -v $GCP_ACCOUNT_FILE:$GCP_ACCOUNT_FILE"
  fi

  if [[ "$AZURE_PUBLISH_SETTINGS" ]]; then
    dockerOpts="$dockerOpts -v $AZURE_PUBLISH_SETTINGS:$AZURE_PUBLISH_SETTINGS"
  fi

  TTY_OPTS="--tty"
  if [[ "$JENKINS_HOME" ]]; then
    ## dont try to use docker tty on jenkins
    TTY_OPTS=""
  fi

  : ${STACK_TYPE:=CDH}
  if [[ "$STACK_TYPE" = "HDP" ]]
  then
    REPOSITORY_NAME="hdp"
  elif [[ "$STACK_TYPE" = "HDF" ]]
  then
    REPOSITORY_NAME="hdf"
  elif [[ "$STACK_TYPE" = "CDH" ]]
  then
    REPOSITORY_NAME="cdh"
  fi

  if [[ -n "$STACK_VERSION" ]]; then
    BASEURL=http://127.0.0.1:28080
    LOCAL_URL_AMBARI=${BASEURL}/ambari/${OS}/ambari-${CLUSTERMANAGER_VERSION}
    LOCAL_URL_HDP=${BASEURL}/${REPOSITORY_NAME}/${OS}/${STACK_TYPE}-${STACK_VERSION}
    LOCAL_URL_HDP_UTILS=${BASEURL}/${REPOSITORY_NAME}/${OS}/HDP-UTILS-${HDPUTIL_VERSION}
  fi

  export DEFAULT_JAVA_MAJOR_VERSION=8
  if [ -n "$STACK_VERSION" ] && [ $(version $STACK_VERSION) -gt $(version "7.3.0") ]; then
    export DEFAULT_JAVA_MAJOR_VERSION=17
  fi
  # Apparently our ARM64 images always go with JDK 17 as the default, even for FreeIPA and base images
  if [[ "$ARCHITECTURE" == "arm64" ]]; then
    export DEFAULT_JAVA_MAJOR_VERSION=17
  fi
  # RHEL 9 has no support for JDK 8, not even for base images
  if [[ "$OS" == "redhat9" ]]; then
    export DEFAULT_JAVA_MAJOR_VERSION=17
  fi

  if [[ "$ENABLE_POSTPROCESSORS" ]]; then
    echo "Postprocessors are enabled"
  else
    echo "Postprocessors are disabled"
    rm -fv packer_no_pp.json
    jq 'del(."post-processors")' packer.json > packer_no_pp.json
    packerFile="packer_no_pp.json"
  fi

  if [[ "$ARCHITECTURE" == "arm64" ]]; then
    if [[ "$CLOUD_PROVIDER" != "AWS" ]]; then
      echo "Architecture arm64 is only supported for AWS"
      exit 1
    fi

    export DEFAULT_JUMPGATE_AGENT_RPM_URL="https://archive.cloudera.com/ccm/3.13.0/jumpgate-agent.aarch64.rpm"
  fi

  if ! [[ $JUMPGATE_AGENT_RPM_URL =~ ^http.*rpm$ ]]; then
      export JUMPGATE_AGENT_RPM_URL=$DEFAULT_JUMPGATE_AGENT_RPM_URL
  fi

  if [ -n "$JUMPGATE_AGENT_RPM_URL" ]; then
    ## Download the jumpgate-agent rpm, get the version and call REDB to lookup the GBN
    wget $JUMPGATE_AGENT_RPM_URL
    JUMPGATE_AGENT_VERSION=$(rpm -qp --queryformat '%{VERSION}' ${JUMPGATE_AGENT_RPM_URL##*/} | sed s/~/-/)
    JUMPGATE_AGENT_GBN=$(curl -Ls "https://release.eng.cloudera.com/hwre-api/latestcompiledbuild?stack=JUMPGATE&release=$JUMPGATE_AGENT_VERSION" --fail | jq -r '.gbn')
  fi

  if ! [[ $FREEIPA_PLUGIN_RPM_URL =~ ^http.*rpm$ ]]; then
    if [[ "$OS" == "redhat9" ]]; then
      if [[ "$ARCHITECTURE" == "arm64" ]]; then
        export FREEIPA_PLUGIN_RPM_URL="https://cloudera-build-2-us-west-2.vpc.cloudera.com/s3/build/73928870/thunderhead/1.x/redhat8/yum/cdp-hashed-pwd-1.1.0.4-b645.el8.aarch64.rpm"   # This is RHEL 8 for now...
      else
        export FREEIPA_PLUGIN_RPM_URL="https://archive.cloudera.com/cdp-freeipa-artifacts/cdp-hashed-pwd-1.1.0.4-b51.el9.x86_64.rpm"
      fi
    elif [[ "$OS" == "redhat8" ]]; then
      if [[ "$ARCHITECTURE" == "arm64" ]]; then
        export FREEIPA_PLUGIN_RPM_URL="https://cloudera-build-2-us-west-2.vpc.cloudera.com/s3/build/73928870/thunderhead/1.x/redhat8/yum/cdp-hashed-pwd-1.1.0.4-b645.el8.aarch64.rpm"
      else
        export FREEIPA_PLUGIN_RPM_URL="https://archive.cloudera.com/cdp-freeipa-artifacts/cdp-hashed-pwd-1.1-b847.el8.x86_64.rpm"
      fi
    else
      export FREEIPA_PLUGIN_RPM_URL=$DEFAULT_FREEIPA_PLUGIN_RPM_URL
    fi
  fi
  if ! [[ $FREEIPA_HEALTH_AGENT_RPM_URL =~ ^http.*rpm$ ]]; then
    if [[ "$OS" == "redhat9" ]]; then
      if [[ "$ARCHITECTURE" == "arm64" ]]; then
        export FREEIPA_HEALTH_AGENT_RPM_URL="https://cloudera-build-2-us-west-2.vpc.cloudera.com/s3/build/73928870/thunderhead/1.x/redhat8/yum/freeipa-health-agent-3.1.0.4-b645.el9.aarch64.rpm" 
      else
        export FREEIPA_HEALTH_AGENT_RPM_URL="https://archive.cloudera.com/cdp-freeipa-artifacts/freeipa-health-agent-3.1.0.4-b141.el9.x86_64.rpm"
      fi
    elif [[ "$OS" == "redhat8" ]]; then
      if [[ "$ARCHITECTURE" == "arm64" ]]; then
        export FREEIPA_HEALTH_AGENT_RPM_URL="https://cloudera-build-2-us-west-2.vpc.cloudera.com/s3/build/73928870/thunderhead/1.x/redhat8/yum/freeipa-health-agent-3.1.0.4-b645.el8.aarch64.rpm"
      else
        export FREEIPA_HEALTH_AGENT_RPM_URL="https://archive.cloudera.com/cdp-freeipa-artifacts/freeipa-health-agent-2.1.0.2-b2228.x86_64.rpm"
      fi
    else
      export FREEIPA_HEALTH_AGENT_RPM_URL=$DEFAULT_FREEIPA_HEALTH_AGENT_RPM_URL
    fi
  fi
  if ! [[  $FREEIPA_LDAP_AGENT_RPM_URL =~ ^http.*rpm$ ]]; then
    if [[ "$OS" == "redhat9" ]]; then
      if [[ "$ARCHITECTURE" == "arm64" ]]; then
        export FREEIPA_LDAP_AGENT_RPM_URL="https://archive.cloudera.com/cdp-freeipa-artifacts/freeipa-ldap-agent-1.1.0.3-b525.aarch64.rpm" # This is RHEL 8 for now...
      else
        export FREEIPA_LDAP_AGENT_RPM_URL="https://archive.cloudera.com/cdp-freeipa-artifacts/freeipa-ldap-agent-1.1.0.4-b51.el9.x86_64.rpm"
      fi
    elif [[ "$OS" == "redhat8" ]]; then
      if [[ "$ARCHITECTURE" == "arm64" ]]; then
        export FREEIPA_LDAP_AGENT_RPM_URL="https://archive.cloudera.com/cdp-freeipa-artifacts/freeipa-ldap-agent-1.1.0.3-b525.aarch64.rpm"
      else
        export FREEIPA_LDAP_AGENT_RPM_URL="https://archive.cloudera.com/cdp-freeipa-artifacts/freeipa-ldap-agent-1.1.0.3-b525.x86_64.rpm"
      fi
    else
      export FREEIPA_LDAP_AGENT_RPM_URL=$DEFAULT_FREEIPA_LDAP_AGENT_RPM_URL
    fi
  fi

  #Fips mode is required for STIG
  if [[ "$STIG_ENABLED" == "true" ]]; then
    FIPS_MODE="true"
  fi

  if [ "$CLOUD_PROVIDER" == "Azure" ]; then
    AZURE_IMAGE_VERSION=$(./scripts/get-azure-vm-image-version.sh "$AZURE_IMAGE_PUBLISHER" "$AZURE_IMAGE_OFFER" "$AZURE_IMAGE_SKU")
    if [ -z "$AZURE_IMAGE_VERSION" ]; then
    	echo "Failed to query AZURE_IMAGE_VERSION"
    	exit 1
    fi
  fi

  if [ "$CLOUD_PROVIDER" == "AWS_GOV" ]; then
    HTTPS_PROXY=http://usgw1-egress.gov-dev.cloudera.com:3128
    HTTP_PROXY=http://usgw1-egress.gov-dev.cloudera.com:3128
    NO_PROXY=172.20.0.0/16,127.0.0.1,localhost,169.254.169.254,internal,local,s3.us-gov-west-1.amazonaws.com,us-gov-west-1.eks.amazonaws.com
  fi

  [[ "$TRACE" ]] && set -x
  ${DRY_RUN:+echo ===} docker run -i $TTY_OPTS --rm \
    -e MOCK=$MOCK \
    -e ORIG_USER=$USER \
    -e GIT_REV=$GIT_REV \
    -e GIT_BRANCH=$GIT_BRANCH \
    -e GIT_TAG=$GIT_TAG \
    -e ARCHITECTURE=$ARCHITECTURE \
    -e OS=$OS \
    -e OS_TYPE=$OS_TYPE \
    -e CHECKPOINT_DISABLE=1 \
    -e PACKER_LOG=$PACKER_LOG \
    -e PACKER_LOG_PATH=$PACKER_LOG_PATH \
    -e BASE_NAME=$BASE_NAME \
    -e IMAGE_BURNING_TYPE=$IMAGE_BURNING_TYPE \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    -e AWS_SECURITY_TOKEN=$AWS_SECURITY_TOKEN \
    -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -e AWS_AMI_REGIONS="$AWS_AMI_REGIONS" \
    -e AWS_INSTANCE_PROFILE="$AWS_INSTANCE_PROFILE" \
    -e AWS_SNAPSHOT_USER="$AWS_SNAPSHOT_USER" \
    -e AWS_SNAPSHOT_GROUPS="$AWS_SNAPSHOT_GROUPS" \
    -e AWS_AMI_GROUPS="$AWS_AMI_GROUPS" \
    -e AWS_AMI_ORG_ARN="$AWS_AMI_ORG_ARN" \
    -e AWS_SOURCE_AMI="$AWS_SOURCE_AMI" \
    -e AWS_INSTANCE_TYPE="$AWS_INSTANCE_TYPE" \
    -e AWS_GOV_SOURCE_AMI="$AWS_GOV_SOURCE_AMI" \
    -e AZURE_IMAGE_VHD=$AZURE_IMAGE_VHD \
    -e AZURE_IMAGE_PUBLISHER=$AZURE_IMAGE_PUBLISHER \
    -e AZURE_IMAGE_OFFER=$AZURE_IMAGE_OFFER \
    -e AZURE_IMAGE_SKU=$AZURE_IMAGE_SKU \
    -e AZURE_IMAGE_VERSION=$AZURE_IMAGE_VERSION \
    -e AZURE_STORAGE_ACCOUNTS="$AZURE_STORAGE_ACCOUNTS" \
    -e ARM_CLIENT_ID=$ARM_CLIENT_ID \
    -e ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET \
    -e ARM_GROUP_NAME=$ARM_GROUP_NAME \
    -e ARM_STORAGE_ACCOUNT=$ARM_STORAGE_ACCOUNT \
    -e ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID \
    -e ARM_TENANT_ID=$ARM_TENANT_ID \
    -e VIRTUAL_NETWORK_RESOURCE_GROUP_NAME=$VIRTUAL_NETWORK_RESOURCE_GROUP_NAME \
    -e ARM_BUILD_REGION=$ARM_BUILD_REGION \
    -e GCP_ACCOUNT_FILE=$GCP_ACCOUNT_FILE \
    -e GCP_STORAGE_BUNDLE=$GCP_STORAGE_BUNDLE \
    -e GCP_SOURCE_IMAGE="$GCP_SOURCE_IMAGE" \
    -e OS_IMAGE_NAME=$OS_IMAGE_NAME \
    -e OS_AUTH_URL=$OS_AUTH_URL \
    -e OS_PASSWORD=$OS_PASSWORD \
    -e OS_TENANT_NAME="$OS_TENANT_NAME" \
    -e OS_USERNAME=$OS_USERNAME \
    -e IMAGE_NAME_SUFFIX=$IMAGE_NAME_SUFFIX \
    -e STACK_TYPE=$STACK_TYPE \
    -e MPACK_URLS=$MPACK_URLS \
    -e STACK_VERSION=$STACK_VERSION \
    -e STACK_BASEURL=$STACK_BASEURL \
    -e STACK_REPOID=$STACK_REPOID \
    -e STACK_REPOSITORY_VERSION=$STACK_REPOSITORY_VERSION \
    -e IMAGE_NAME=$IMAGE_NAME \
    -e IMAGE_SIZE=$IMAGE_SIZE \
    -e PREWARM_TAG=$PREWARM_TAG \
    -e INCLUDE_FLUENT=$INCLUDE_FLUENT \
    -e INCLUDE_CDP_TELEMETRY=$INCLUDE_CDP_TELEMETRY \
    -e FLUENT_PREWARM_TAG=$FLUENT_PREWARM_TAG \
    -e CDP_TELEMETRY_PREWARM_TAG=$CDP_TELEMETRY_PREWARM_TAG \
    -e USE_TELEMETRY_ARCHIVE=$USE_TELEMETRY_ARCHIVE \
    -e HDPUTIL_VERSION=$HDPUTIL_VERSION \
    -e HDPUTIL_BASEURL=$HDPUTIL_BASEURL \
    -e HDPUTIL_REPOID=$HDPUTIL_REPOID \
    -e CLUSTERMANAGER_VERSION=$CLUSTERMANAGER_VERSION \
    -e CLUSTERMANAGER_BASEURL=$CLUSTERMANAGER_BASEURL \
    -e CLUSTERMANAGER_GPGKEY=$CLUSTERMANAGER_GPGKEY \
    -e ATLAS_TOKEN=$ATLAS_TOKEN \
    -e LOCAL_URL_AMBARI=$LOCAL_URL_AMBARI \
    -e LOCAL_URL_HDP=$LOCAL_URL_HDP \
    -e LOCAL_URL_HDP_UTILS=$LOCAL_URL_HDP_UTILS \
    -e SALT_INSTALL_OS=$SALT_INSTALL_OS \
    -e SALT_INSTALL_REPO=$SALT_INSTALL_REPO \
    -e ATLAS_ARTIFACT_TYPE=$ATLAS_ARTIFACT_TYPE \
    -e COPY_AWS_MARKETPLACE_EULA=$COPY_AWS_MARKETPLACE_EULA \
    -e CUSTOM_IMAGE_TYPE=$CUSTOM_IMAGE_TYPE \
    -e OWNER_TAG=$OWNER_TAG \
    -e CLOUDERA_USAGE_TYPE_TAG=$CLOUDERA_USAGE_TYPE_TAG \
    -e OPTIONAL_STATES=$OPTIONAL_STATES \
    -e PREINSTALLED_JAVA_HOME=$PREINSTALLED_JAVA_HOME \
    -e DESCRIPTION="$DESCRIPTION" \
    -e REPOSITORY_TYPE="$REPOSITORY_TYPE" \
    -e SLES_REGISTRATION_CODE="$SLES_REGISTRATION_CODE" \
    -e PACKAGE_VERSIONS="$PACKAGE_VERSIONS" \
    -e TAGS="$TAGS" \
    -e AWS_MAX_ATTEMPTS=$AWS_MAX_ATTEMPTS \
    -e SALT_VERSION="$SALT_VERSION" \
    -e SALT_PATH="$SALT_PATH" \
    -e PYZMQ_VERSION="$PYZMQ_VERSION" \
    -e PYTHON_APT_VERSION="$PYTHON_APT_VERSION" \
    -e SALT_REPO_FILE=$SALT_REPO_FILE \
    -e TAG_CUSTOMER_DELIVERED="$TAG_CUSTOMER_DELIVERED" \
    -e VERSION="$VERSION" \
    -e PARCELS_NAME="$PARCELS_NAME" \
    -e PARCELS_ROOT="$PARCELS_ROOT" \
    -e PRE_WARM_PARCELS="${PRE_WARM_PARCELS}" \
    -e PRE_WARM_CSD="${PRE_WARM_CSD}" \
    -e VPC_ID="$VPC_ID" \
    -e SUBNET_ID="$SUBNET_ID" \
    -e BASE_AMI_ID="$BASE_AMI_ID" \
    -e CM_BUILD_NUMBER="$CM_BUILD_NUMBER" \
    -e STACK_BUILD_NUMBER="$STACK_BUILD_NUMBER" \
    -e COMPOSITE_GBN="$COMPOSITE_GBN" \
    -e PARCEL_LIST_WITH_VERSIONS="$PARCEL_LIST_WITH_VERSIONS" \
    -e METADATA_FILENAME_POSTFIX="$METADATA_FILENAME_POSTFIX" \
    -e CDP_TELEMETRY_VERSION="$CDP_TELEMETRY_VERSION" \
    -e CDP_LOGGING_AGENT_VERSION="$CDP_LOGGING_AGENT_VERSION" \
    -e JUMPGATE_AGENT_RPM_URL="$JUMPGATE_AGENT_RPM_URL" \
    -e JUMPGATE_AGENT_GBN="$JUMPGATE_AGENT_GBN" \
    -e FREEIPA_PLUGIN_RPM_URL="$FREEIPA_PLUGIN_RPM_URL" \
    -e FREEIPA_HEALTH_AGENT_RPM_URL="$FREEIPA_HEALTH_AGENT_RPM_URL" \
    -e FREEIPA_LDAP_AGENT_RPM_URL="$FREEIPA_LDAP_AGENT_RPM_URL" \
    -e IMAGE_UUID="$IMAGE_UUID" \
    -e CLOUD_PROVIDER="$CLOUD_PROVIDER" \
    -e SSH_PUBLIC_KEY="$SSH_PUBLIC_KEY" \
    -e FIPS_MODE="$FIPS_MODE" \
    -e STIG_ENABLED="$STIG_ENABLED" \
    -e OSCAP_SCAN_ENABLED="$OSCAP_SCAN_ENABLED" \
    -e PACKER_VERSION="$PACKER_VERSION" \
    -e DEFAULT_JAVA_MAJOR_VERSION="$DEFAULT_JAVA_MAJOR_VERSION" \
    -e SALTBOOT_VERSION="$SALTBOOT_VERSION" \
    -e SALTBOOT_HTTPS_ENABLED="$SALTBOOT_HTTPS_ENABLED" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $PWD:$PWD \
    -w $PWD \
    --entrypoint /bin/bash \
    $dockerOpts \
    hashicorp/packer:$PACKER_VERSION \
    -c "./scripts/packer-command.sh $* $packerFile"
}

main() {
  echo $IMAGE_NAME
  packer_in_container "$@"
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
