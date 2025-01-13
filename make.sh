#!/bin/bash

setenvs() {

	export BASE_NAME="${BASE_NAME:-cb}"
	export CLOUD_PROVIDER="${CLOUD_PROVIDER:-}"
	export DESCRIPTION="${DESCRIPTION:Official Cloudbreak image}"
	export STACK_TYPE="${STACK_TYPE:CDH}"
	export STACK_VERSION="${STACK_VERSION:-}"
	export ATLAS_PROJECT="${ATLAS_PROJECT:-cloudbreak}"
	export ENABLE_POSTPROCESSORS="${ENABLE_POSTPROCESSORS:-}"
	export REPOSITORY_TYPE="${REPOSITORY_TYPE:-}"
	export FIPS_MODE="${FIPS_MODE:-false}"
	export STIG_ENABLED="${STIG_ENABLED:-false}"
	export CUSTOM_IMAGE_TYPE="${CUSTOM_IMAGE_TYPE:-hortonworks}"
	export IMAGE_OWNER="${IMAGE_OWNER:-cloudbreak-dev}"
	export OPTIONAL_STATES="${OPTIONAL_STATES:-}"
	export IMAGE_COPY_PHASE="${IMAGE_COPY_PHASE:-}" # for splitting image copy (test and prod phases)
	export ARCHITECTURE="${ARCHITECTURE:-x86_64}"

	# Azure VM image specifications
	if [ "$CLOUD_PROVIDER" = "Azure" ]; then
		export PRIVATE_VIRTUAL_NETWORK_WITH_PUBLIC_IP="${PRIVATE_VIRTUAL_NETWORK_WITH_PUBLIC_IP:-false}"
		export AZURE_INITIAL_COPY="${AZURE_INITIAL_COPY:-true}"

		if [ ! -z "$BUILD_RESOURCE_GROUP_NAME" ]; then
			if [ ! -z "$ARM_BUILD_REGION" ]; then
				echo BUILD_RESOURCE_GROUP_NAME and ARM_BUILD_REGION should not be set together!
				exit 1
			else
				ARM_BUILD_REGION="${ARM_BUILD_REGION:-northeurope}"
			fi
		fi
		export ARM_BUILD_REGION=$ARM_BUILD_REGION		

		if [ ! -z "$AZURE_IMAGE_VHD" ]; then
			AZURE_IMAGE_MARKETPLACE_SET=false
			if [ ! -z "$AZURE_IMAGE_PUBLISHER" ]; then
				AZURE_IMAGE_MARKETPLACE_SET=true
			fi
			if [ ! -z "$AZURE_IMAGE_OFFER" ]; then
				AZURE_IMAGE_MARKETPLACE_SET=true
			fi
			if [ ! -z "$AZURE_IMAGE_SKU" ]; then
				AZURE_IMAGE_MARKETPLACE_SET=true
			fi
			if [ "$AZURE_IMAGE_MARKETPLACE_SET" = "true" ]; then
				echo "AZURE_IMAGE_VHD and Marketplace image properties (AZURE_IMAGE_PUBLISHER, AZURE_IMAGE_OFFER, AZURE_IMAGE_SKU) should not be set together!"
				exit 1
			fi
		else
			if [ "$OS" = "redhat8" ]; then
				AZURE_IMAGE_PUBLISHER="${AZURE_IMAGE_PUBLISHER:-RedHat}"
				AZURE_IMAGE_OFFER="${AZURE_IMAGE_OFFER:-rhel-byos}"
				if [ "$STACK_VERSION" = "7.3.1" ]; then
					AZURE_IMAGE_SKU="${AZURE_IMAGE_SKU:-rhel-lvm810}"
				elif [ "$STACK_VERSION" = "7.2.18" ]; then
					AZURE_IMAGE_SKU="${AZURE_IMAGE_SKU:-rhel-lvm810}"
				elif [ "$IMAGE_BURNING_TYPE" = "base" ]; then
					AZURE_IMAGE_SKU="${AZURE_IMAGE_SKU:-rhel-lvm810}"
				elif [ "$CUSTOM_IMAGE_TYPE" = "freeipa" ]; then
					AZURE_IMAGE_SKU="${AZURE_IMAGE_SKU:-rhel-lvm810}"
				else
					AZURE_IMAGE_SKU="${AZURE_IMAGE_SKU:-rhel-lvm88}"
				fi
			elif [ "$OS" = "centos7" ]; then
				AZURE_IMAGE_PUBLISHER="${AZURE_IMAGE_PUBLISHER:-OpenLogic}"
				AZURE_IMAGE_OFFER="${AZURE_IMAGE_OFFER:-CentOS}"
				AZURE_IMAGE_SKU="${AZURE_IMAGE_SKU:-7.6}"
			elif [ ! -z "$OS" ]; then
				echo "Unexpected OS type $OS for Azure!"
				exit 1
			fi
			export AZURE_IMAGE_PUBLISHER=$AZURE_IMAGE_PUBLISHER
			export AZURE_IMAGE_OFFER=$AZURE_IMAGE_OFFER
			export AZURE_IMAGE_SKU=$AZURE_IMAGE_SKU
		fi

		if [ ! -z "$OS_VERSION" ]; then
			if [ "$OS_VERSION" = "8.8" ]; then
				PLAN_NAME="${PLAN_NAME:-rhel-lvm88}"
			elif [ "$OS_VERSION" = "8.10" ]; then
				PLAN_NAME="${PLAN_NAME:-rhel-lvm810}"
			else
				echo "Unsupported OS version \"$OS_VERSION\" for Azure!"
				exit 1
			fi
			export PLAN_NAME=$PLAN_NAME
		fi
	fi

	# AWS source ami and instance type specification
	if [ "$CLOUD_PROVIDER" = "AWS" ]; then
		if [ "$OS" = "centos7" ]; then
			AWS_SOURCE_AMI="${ami-098f55b4287a885ba}"
			AWS_INSTANCE_TYPE="${t3.2xlarge}"
		elif [ "$OS" = "redhat8" ]; then
			if [ "$ARCHITECTURE" = "arm64" ]; then
				AWS_SOURCE_AMI="${AWS_SOURCE_AMI:-ami-05032c39067d77b1b}"
				AWS_INSTANCE_TYPE="${AWS_INSTANCE_TYPE:-r7gd.2xlarge}"
			else
				if [ "$STACK_VERSION" = "7.3.1" ]; then
					AWS_SOURCE_AMI="${AWS_SOURCE_AMI:-ami-02073841a355a1e92}"
				elif [ "$STACK_VERSION" = "7.2.18" ]; then
					AWS_SOURCE_AMI="${AWS_SOURCE_AMI:-ami-02073841a355a1e92}"
				elif [ "$IMAGE_BURNING_TYPE" = "base" ]; then
					AWS_SOURCE_AMI="${AWS_SOURCE_AMI:-ami-02073841a355a1e92}"
				elif [ "$CUSTOM_IMAGE_TYPE" = "freeipa" ]; then
					AWS_SOURCE_AMI="${AWS_SOURCE_AMI:-ami-02073841a355a1e92}"
				else
					AWS_SOURCE_AMI="${AWS_SOURCE_AMI:-ami-039ce2eddc1949546}"
				fi
				AWS_INSTANCE_TYPE="${AWS_INSTANCE_TYPE:-t3.2xlarge}"
			fi
		elif [ ! -z "$OS" ]; then
			echo "Unexpected OS type $OS for AWS!"
			exit 1
		fi
		export AWS_SOURCE_AMI=$AWS_SOURCE_AMI
		export AWS_INSTANCE_TYPE=$AWS_INSTANCE_TYPE
	fi

	# AWS_GOV source ami specification
	if [ "$CLOUD_PROVIDER" = "AWS_GOV" ]; then
		AWS_INSTANCE_TYPE="${AWS_INSTANCE_TYPE:-t3.2xlarge}"
		if [ "$OS" = "redhat8" ]; then
			AWS_GOV_SOURCE_AMI="${AWS_SOURCE_AMI:-ami-0ac4e06a69870e5be}"
		elif [ ! -z "$OS" ]; then
			echo "Unexpected OS type $OS for AWS Gov!"
			exit 1
		fi
		export AWS_SOURCE_AMI=$AWS_SOURCE_AMI
		export AWS_INSTANCE_TYPE=$AWS_INSTANCE_TYPE
	fi

	# GCP source image specification
	if [ "$CLOUD_PROVIDER" = "GCP" ]; then
		if [ "$OS" = "centos7" ]; then
			GCP_SOURCE_IMAGE="${GCP_SOURCE_IMAGE:-centos-7-v20200811}"
		elif [ "$OS" = "redhat8" ]; then
			if [ "$STACK_VERSION" = "7.3.1" ]; then
				GCP_SOURCE_IMAGE="${GCP_SOURCE_IMAGE:-rhel-8-byos-v20240709}"
			elif [ "$STACK_VERSION" = "7.2.18" ]; then
				GCP_SOURCE_IMAGE="${GCP_SOURCE_IMAGE:-rhel-8-byos-v20240709}"
			elif [ "$IMAGE_BURNING_TYPE" = "base" ]; then
				GCP_SOURCE_IMAGE="${GCP_SOURCE_IMAGE:-rhel-8-byos-v20240709}"
			elif [ "$CUSTOM_IMAGE_TYPE" = "freeipa" ]; then
				GCP_SOURCE_IMAGE="${GCP_SOURCE_IMAGE:-rhel-8-byos-v20240709}"
			else
				GCP_SOURCE_IMAGE="${GCP_SOURCE_IMAGE:-rhel-8-byos-v20230615}"
			fi
		elif [ ! -z "$OS" ]; then
			echo "Unexpected OS type $OS for GCP!"
			exit 1
		fi
		export GCP_SOURCE_IMAGE=$GCP_SOURCE_IMAGE
	fi

	export DOCKER_REPOSITORY="${DOCKER_REPOSITORY:-docker-sandbox.infra.cloudera.com}"
	export DOCKER_REPO_USERNAME="${DOCKER_REPO_USERNAME:-}"
	export DOCKER_REPO_PASSWORD="${DOCKER_REPO_PASSWORD:-}"

	# This needs to be changed if there is a version change in fluent components. See usage in the salt files in the Cloudbreak repo.
	# Deprecated: do not increase it anymore, but it can be removed only if no images in use with date before this line is committed.
	export FLUENT_PREWARM_TAG="${FLUENT_PREWARM_TAG:-fluent_prewarmed_v5}"
	# This needs to be changed if there is a version change in metering heartbeat component. See usage in the salt files in the Cloudbreak repo.
	export METERING_PREWARM_TAG="${METERING_PREWARM_TAG:-metering_prewarmed_v3}"
	# This needs to be changed if there is a version change in cdp-telemetry cli component. See usage in the salt files in the Cloudbreak repo.
	# Deprecated: do not increase it anymore, but it can be removed only if no images in use with date before this line is committed.
	export CDP_TELEMETRY_PREWARM_TAG="${CDP_TELEMETRY_PREWARM_TAG:-cdp_telemetry_prewarmed_v12}"
	# This needs to be changed if there is a version change in components other than fluent, or if there are relevant changes to the salt scripts in Cloudbreak.
	export PREWARM_TAG="${PREWARM_TAG:prewarmed_v1}"

	## https://github.com/hashicorp/packer/issues/6536
	export AWS_MAX_ATTEMPTS="${AWS_MAX_ATTEMPTS:-300}"
	export PACKAGE_VERSIONS="${PACKAGE_VERSIONS:-}"
	export SALT_VERSION="${SALT_VERSION:-$(./scripts/get-salt-version.sh $BASE_NAME $STACK_VERSION)}"
	export SALT_PATH="${SALT_PATH:-/opt/salt_$SALT_VERSION}"

	SALT_NEWER_PYZMQ=$(echo "$SALT_VERSION>=3006.4" | bc)
	if [ "$SALT_NEWER_PYZMQ" = "1" ]; then
		PYZMQ_VERSION="${PYZMQ_VERSION:-25.0.2}"
	else
		PYZMQ_VERSION="${PYZMQ_VERSION:-19.0}"
	fi
	export PYZMQ_VERSION=$PYZMQ_VERSION

	export SALTBOOT_VERSION="${SALTBOOT_VERSION:-0.14.0}"

	SALTBOOT_MINOR_VERSION=$(echo $SALTBOOT_VERSION | cut -d. -f2)
	if [[ $SALTBOOT_MINOR_VERSION -ge 14 ]]; then
		SALTBOOT_HTTPS_ENABLED=false
	else
		SALTBOOT_HTTPS_ENABLED=false
	fi
	export SALTBOOT_HTTPS_ENABLED=$SALTBOOT_HTTPS_ENABLED

	# This block remains here for backward compatibility reasons when the IMAGE_NAME is not defined as an env variable
	if [ -z "$IMAGE_NAME" ]; then
		STACK_VERSION_SHORT=$STACK_TYPE-$(echo $STACK_VERSION | tr -d . | cut -c1-4)
		export IMAGE_NAME=$BASE_NAME-$(echo $STACK_VERSION_SHORT | tr '[:upper:]' '[:lower:]')-$(date +%s)$IMAGE_NAME_SUFFIX
		echo IMAGE_NAME was not defined as an environment variable. Generated value: $IMAGE_NAME
	fi

	export IMAGE_SIZE=$(./scripts/get-image-size.sh $CLOUD_PROVIDER $OS $STACK_VERSION $ARCHITECTURE)

	export AWS_SNAPSHOT_USER=$AWS_SNAPSHOT_USER
	export AWS_AMI_GROUPS=$AWS_AMI_GROUPS
	export AWS_AMI_ORG_ARN=$AWS_AMI_ORG_ARN

	if [ "$MAKE_PUBLIC_SNAPSHOTS" = "yes" ]; then
		export AWS_SNAPSHOT_GROUPS=all
	fi

	if [ "$MAKE_PUBLIC_AMIS" = "yes" ]; then
		export AWS_AMI_GROUPS=all
	fi

	export TAG_CUSTOMER_DELIVERED="${TAG_CUSTOMER_DELIVERED:-No}"
	export INCLUDE_FLUENT="${INCLUDE_FLUENT:-Yes}"
	export INCLUDE_CDP_TELEMETRY="${INCLUDE_CDP_TELEMETRY:-Yes}"
	export INCLUDE_METERING="${INCLUDE_METERING:-Yes}"
	export USE_TELEMETRY_ARCHIVE="${USE_TELEMETRY_ARCHIVE:-Yes}"

	# This one is OS-independent (right?)
	export DEFAULT_JUMPGATE_AGENT_RPM_URL=https://archive.cloudera.com/ccm/3.8.0/jumpgate-agent.rpm

	# This one is OS-independent (v2.0 is a rewrite done in GoLang)
	export DEFAULT_METERING_AGENT_RPM_URL=https://archive.cloudera.com/cp_clients/thunderhead-metering-heartbeat-application-2.0.0-b12639.x86_64.rpm

	# This one is theoretically OS-dependent and will be overridden in packer.sh for RHEL8, even though apparently packages work regardless of the OS.
	export DEFAULT_FREEIPA_PLUGIN_RPM_URL=https://archive.cloudera.com/cdp-freeipa-artifacts/cdp-hashed-pwd-1.1-b847.el7.x86_64.rpm

	# This one is OS-independent
	export DEFAULT_FREEIPA_HEALTH_AGENT_RPM_URL=https://archive.cloudera.com/cdp-freeipa-artifacts/freeipa-health-agent-0.1-20241118074445git3006935.x86_64.rpm

	# This one is OS-independent
	export DEFAULT_FREEIPA_LDAP_AGENT_RPM_URL=https://archive.cloudera.com/cdp-freeipa-artifacts/freeipa-ldap-agent-1.0.0-b12478.x86_64.rpm

	# What are these?! (Probably leftover legacy stuff)
	export PREINSTALLED_JAVA_HOME="${PREINSTALLED_JAVA_HOME:-}"
	export VERSION="${VERSION:-}"

	#export ENVS="METADATA_FILENAME_POSTFIX=$METADATA_FILENAME_POSTFIX DESCRIPTION=$DESCRIPTION STACK_TYPE=$STACK_TYPE MPACK_URLS=$MPACK_URLS HDP_VERSION=$HDP_VERSION BASE_NAME=$BASE_NAME IMAGE_NAME=$IMAGE_NAME IMAGE_SIZE=$IMAGE_SIZE INCLUDE_CDP_TELEMETRY=$INCLUDE_CDP_TELEMETRY INCLUDE_FLUENT=$INCLUDE_FLUENT INCLUDE_METERING=$INCLUDE_METERING USE_TELEMETRY_ARCHIVE=$USE_TELEMETRY_ARCHIVE ENABLE_POSTPROCESSORS=$ENABLE_POSTPROCESSORS CUSTOM_IMAGE_TYPE=$CUSTOM_IMAGE_TYPE OPTIONAL_STATES=$OPTIONAL_STATES PREINSTALLED_JAVA_HOME=${PREINSTALLED_JAVA_HOME} IMAGE_OWNER=${IMAGE_OWNER} REPOSITORY_TYPE=${REPOSITORY_TYPE} PACKAGE_VERSIONS=$PACKAGE_VERSIONS SALT_VERSION=$SALT_VERSION SALT_PATH=$SALT_PATH PYZMQ_VERSION=$PYZMQ_VERSION PYTHON_APT_VERSION=$PYTHON_APT_VERSION AWS_MAX_ATTEMPTS=$AWS_MAX_ATTEMPTS TRACE=1 AWS_SNAPSHOT_GROUPS=$AWS_SNAPSHOT_GROUPS AWS_SNAPSHOT_USER=$AWS_SNAPSHOT_USER AWS_AMI_GROUPS=$AWS_AMI_GROUPS AWS_AMI_ORG_ARN=$AWS_AMI_ORG_ARN TAG_CUSTOMER_DELIVERED=$TAG_CUSTOMER_DELIVERED VERSION=$VERSION PARCELS_NAME=$PARCELS_NAME PARCELS_ROOT=$PARCELS_ROOT SUBNET_ID=$SUBNET_ID VPC_ID=$VPC_ID VIRTUAL_NETWORK_RESOURCE_GROUP_NAME=$VIRTUAL_NETWORK_RESOURCE_GROUP_NAME ARM_BUILD_REGION=$ARM_BUILD_REGION PRE_WARM_PARCELS=$PRE_WARM_PARCELS PRE_WARM_CSD=$PRE_WARM_CSD SLES_REGISTRATION_CODE=$SLES_REGISTRATION_CODE FLUENT_PREWARM_TAG=$FLUENT_PREWARM_TAG METERING_PREWARM_TAG=$METERING_PREWARM_TAG CDP_TELEMETRY_PREWARM_TAG=$CDP_TELEMETRY_PREWARM_TAG PREWARM_TAG=$PREWARM_TAG DEFAULT_JUMPGATE_AGENT_RPM_URL=$DEFAULT_JUMPGATE_AGENT_RPM_URL DEFAULT_METERING_AGENT_RPM_URL=$DEFAULT_METERING_AGENT_RPM_URL DEFAULT_FREEIPA_PLUGIN_RPM_URL=$DEFAULT_FREEIPA_PLUGIN_RPM_URL DEFAULT_FREEIPA_HEALTH_AGENT_RPM_URL=$DEFAULT_FREEIPA_HEALTH_AGENT_RPM_URL DEFAULT_FREEIPA_LDAP_AGENT_RPM_URL=$DEFAULT_FREEIPA_LDAP_AGENT_RPM_URL CLOUD_PROVIDER=$CLOUD_PROVIDER SSH_PUBLIC_KEY=$SSH_PUBLIC_KEY FIPS_MODE=$FIPS_MODE STIG_ENABLED=$STIG_ENABLED SALTBOOT_VERSION=$SALTBOOT_VERSION SALTBOOT_HTTPS_ENABLED=$SALTBOOT_HTTPS_ENABLED"
	export METADATA_FILENAME_POSTFIX=$METADATA_FILENAME_POSTFIX
	export TRACE=1

	export PARCELS_NAME=$PARCELS_NAME 
	export PARCELS_ROOT=$PARCELS_ROOT
	export SUBNET_ID=$SUBNET_ID
	export VPC_ID=$VPC_ID 
	export VIRTUAL_NETWORK_RESOURCE_GROUP_NAME=$VIRTUAL_NETWORK_RESOURCE_GROUP_NAME
	export PRE_WARM_PARCELS=$PRE_WARM_PARCELS 
	export PRE_WARM_CSD=$PRE_WARM_CSD 

	export GITHUB_ORG="${GITHUB_ORG:-hortonworks}"
	export GITHUB_REPO="${GITHUB_REPO:-cloudbreak-images-metadata}"
	export GIT_REV=$(git rev-parse HEAD)
	export GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
	export GIT_TAG=$(git describe --exact-match --tags 2>/dev/null)

	export SSH_PUBLIC_KEY=$SSH_PUBLIC_KEY

	if [ ! -z "$DOCKER_VERSION" ]; then
		PACKER_VARS="$PACKER_VARS -var yum_version_docker=$DOCKER_VERSION"
	fi

	if [ "$MOCK" = "true" ]; then
		PACKER_OPTS="$PACKER_VARS -var atlas_artifact=mock"
	else
		PACKER_OPTS=$PACKER_VARS
	fi

	if [ "$CUSTOM_IMAGE_TYPE" = "freeipa" ]; then
		export BASE_NAME=freeipa
	fi

	export GCP_STORAGE_BUNDLE="cloudera-$BASE_NAME-images"
	export GCP_STORAGE_BUNDLE_LOG="cloudera-$BASE_NAME-images"

	# AWS AMI region definitions for the different states
	AWS_AMI_REGIONS_TEST_PHASE="us-west-1,us-west-2,eu-central-1,eu-west-1"
	AWS_AMI_REGIONS_ALL="ap-northeast-1,ap-northeast-2,ap-south-1,ap-south-2,ap-southeast-1,ap-southeast-2,ap-southeast-3,ca-central-1,ca-west-1,eu-central-1,eu-west-1,eu-west-2,eu-west-3,sa-east-1,us-east-1,us-east-2,us-west-1,us-west-2,eu-north-1,eu-south-1,af-south-1,me-south-1,ap-east-1,eu-south-2,eu-central-2,me-central-1,il-central-1"

	if [ -z "$AWS_AMI_REGIONS" ]; then
		AWS_AMI_REGIONS=$AWS_AMI_REGIONS_ALL
		if [ "$IMAGE_COPY_PHASE" = "test" ]; then
			AWS_AMI_REGIONS=$AWS_AMI_REGIONS_TEST_PHASE
		fi
		export AWS_AMI_REGIONS=$AWS_AMI_REGIONS
	fi

	# Azure storage account definitions for the different states
	AZURE_STORAGE_ACCOUNTS_TEST_PHASE="West US:cldrwestus,\
	West US 2:cldrwestus2,\
	East US:cldreastus,\
	East US 2:cldreastus2,\
	Central US:cldrcentralus"

	AZURE_STORAGE_ACCOUNTS_ALL="East Asia:cldreastasia,\
	East US:cldreastus,\
	Central US:cldrcentralus,\
	North Europe:cldrnortheurope,\
	South Central US:cldrsouthcentralus,\
	North Central US:cldrnorthcentralus,\
	East US 2:cldreastus2,\
	Japan East:cldrjapaneast,\
	Japan West:cldrjapanwest,\
	Southeast Asia:cldrsoutheastasia,\
	West US:cldrwestus,\
	West Europe:cldrwesteurope,\
	Brazil South:cldrbrazilsouth,\
	Canada East:cldrcanadaeast,\
	Canada Central:cldrcanadacentral,\
	Australia East:cldraustraliaeast,\
	Australia Southeast:cldraustralisoutheast,\
	Central India:cldrcentralindia,\
	Korea Central:cldrkoreacentral,\
	Korea South:cldrkoreasouth,\
	South India:cldrsouthindia,\
	UK South:cldruksouth,\
	West Central US:cldrwestcentralus,\
	UK West:cldrukwest,\
	West US 2:cldrwestus2,\
	West India:cldrwestindia,\
	Australia Central:cldraustraliacentral,\
	UAE North:cldruaenorth,\
	South Africa North:cldrsouthafricanorth,\
	France Central:cldrfrancecentral,\
	Switzerland North:cldrswitzerlandnorth,\
	Germany West Central:cldrgermanywestcentral,\
	Norway East:cldrnorwayeast,\
	Qatar Central:cldrqatarcentral"

	if [ -z "$AZURE_STORAGE_ACCOUNTS" ]; then
		AZURE_STORAGE_ACCOUNTS=$AZURE_STORAGE_ACCOUNTS_ALL
		if [ "$IMAGE_COPY_PHASE" = "test" ]; then
			AZURE_STORAGE_ACCOUNTS=$AZURE_STORAGE_ACCOUNTS_TEST_PHASE
		fi
		export AZURE_STORAGE_ACCOUNTS=$AZURE_STORAGE_ACCOUNTS
	fi

	export AWS_GOV_AMI_REGIONS="us-gov-west-1,us-gov-east-1"
	export AZURE_BUILD_STORAGE_ACCOUNT="West US:cldrwestus"
	export S3_TARGET="s3://public-repo-1.hortonworks.com/HDP/cloudbreak"
}

show-image-name() {
	echo IMAGE_NAME=$IMAGE_NAME
}

build-aws-centos7-base() {
	$ENVS \
	AWS_AMI_REGIONS="us-west-1" \
	AWS_SOURCE_AMI=$AWS_SOURCE_AMI \
	AWS_INSTANCE_TYPE=$AWS_INSTANCE_TYPE \
	OS=centos7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=centos \
	GIT_REV=$GIT_REV \
	GIT_BRANCH=$GIT_BRANCH \
	GIT_TAG=$GIT_TAG \
	./scripts/packer.sh build -color=false -only=aws-centos7 $PACKER_OPTS
}

build-aws-centos7() {
	METADATA_FILENAME_POSTFIX=$METADATA_FILENAME_POSTFIX
	
	build-aws-centos7-base

	$ENVS \
	AWS_AMI_REGIONS="$AWS_AMI_REGIONS" \
	AWS_SOURCE_AMI=$AWS_SOURCE_AMI \
	AWS_INSTANCE_TYPE=$AWS_INSTANCE_TYPE \
	ATLAS_ARTIFACT_TYPE=amazon \
	GIT_REV=$GIT_REV \
	GIT_BRANCH=$GIT_BRANCH \
	GIT_TAG=$GIT_TAG \
	./scripts/sparseimage/packer.sh build -color=false -force $PACKER_OPTS
}

build-aws-redhat8() {
	AWS_AMI_REGIONS="us-west-1" \
	OS=redhat8 \
	OS_TYPE=redhat8 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=redhat \
	./scripts/packer.sh build -color=false -only=aws-redhat8 $PACKER_OPTS
}

build-azure-redhat8() {
	$ENVS \
	AZURE_STORAGE_ACCOUNTS=$AZURE_BUILD_STORAGE_ACCOUNT \
	OS=redhat8 \
	OS_TYPE=redhat8 \
	ATLAS_ARTIFACT_TYPE=azure-arm \
	SALT_INSTALL_OS=redhat \
	AZURE_IMAGE_VHD=$AZURE_IMAGE_VHD \
	AZURE_IMAGE_PUBLISHER=$AZURE_IMAGE_PUBLISHER \
	AZURE_IMAGE_OFFER=$AZURE_IMAGE_OFFER \
	AZURE_IMAGE_SKU=$AZURE_IMAGE_SKU \
	BUILD_RESOURCE_GROUP_NAME=$BUILD_RESOURCE_GROUP_NAME \
	PRIVATE_VIRTUAL_NETWORK_WITH_PUBLIC_IP=$PRIVATE_VIRTUAL_NETWORK_WITH_PUBLIC_IP \
	GIT_REV=$GIT_REV \
	GIT_BRANCH=$GIT_BRANCH \
	GIT_TAG=$GIT_TAG \
	./scripts/packer.sh build -color=false -only=arm-redhat8 $PACKER_OPTS
	if [ "$AZURE_INITIAL_COPY" = "true" ]; then
		TRACE=1 AZURE_STORAGE_ACCOUNTS=$AZURE_BUILD_STORAGE_ACCOUNT ./scripts/azure-copy.sh
	fi
}

build-gc-redhat8() {
	METADATA_FILENAME_POSTFIX=$METADATA_FILENAME_POSTFIX
	$ENVS \
	OS=redhat8 \
	OS_TYPE=redhat8 \
	GCP_SOURCE_IMAGE=$GCP_SOURCE_IMAGE \
	ATLAS_ARTIFACT_TYPE=google \
	GCP_STORAGE_BUNDLE=$GCP_STORAGE_BUNDLE \
	GCP_STORAGE_BUNDLE_LOG=$GCP_STORAGE_BUNDLE_LOG \
	SALT_INSTALL_OS=redhat \
	GIT_REV=$GIT_REV \
	GIT_BRANCH=$GIT_BRANCH \
	GIT_TAG=$GIT_TAG \
	./scripts/packer.sh build -color=false -only=gc-redhat8 $PACKER_OPTS
}

copy-aws-images() {
	docker run -i --rm \
		-v "$PWD/scripts:/scripts" \
		-w /scripts \
		-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
		-e AWS_AMI_REGIONS=$AWS_AMI_REGIONS \
		-e IMAGE_NAME=$IMAGE_NAME \
		-e SOURCE_LOCATION=$SOURCE_LOCATION \
		-e MAKE_PUBLIC_AMIS=$MAKE_PUBLIC_AMIS \
		-e MAKE_PUBLIC_SNAPSHOTS=$MAKE_PUBLIC_SNAPSHOTS \
		-e AWS_AMI_ORG_ARN=$AWS_AMI_ORG_ARN \
		-e AWS_SNAPSHOT_USER=$AWS_SNAPSHOT_USER \
		--entrypoint="/bin/bash" \
		amazon/aws-cli -c "./aws-copy.sh"
}

build-aws-gov-centos7-base() {
	echo Not supported!
}

build-aws-gov-centos7() {
	echo Not supported!
}

build-aws-gov-redhat8() {
	$ENVS \
	AWS_AMI_REGIONS="us-gov-west-1" \
	AWS_GOV_SOURCE_AMI=$AWS_GOV_SOURCE_AMI \
	AWS_INSTANCE_TYPE=$AWS_INSTANCE_TYPE \
	OS=redhat8 \
	OS_TYPE=redhat8 \
	ATLAS_ARTIFACT_TYPE=amazon-gov \
	SALT_INSTALL_OS=redhat \
	GIT_REV=$GIT_REV \
	GIT_BRANCH=$GIT_BRANCH \
	GIT_TAG=$GIT_TAG \
	HTTPS_PROXY=http://usgw1-egress.gov-dev.cloudera.com:3128 \
	HTTP_PROXY=http://usgw1-egress.gov-dev.cloudera.com:3128 \
	NO_PROXY=172.20.0.0/16,127.0.0.1,localhost,169.254.169.254,internal,local,s3.us-gov-west-1.amazonaws.com,us-gov-west-1.eks.amazonaws.com \
	PACKER_VERSION="1.8.3" \
	./scripts/packer.sh build -color=false -only=aws-gov-redhat8 $PACKER_OPTS
}

copy-aws-gov-images() {
	docker run -i --rm \
		-v "${PWD}/scripts:/scripts" \
		-w /scripts \
		-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
		-e AWS_AMI_REGIONS=$AWS_GOV_AMI_REGIONS \
		-e IMAGE_NAME=$IMAGE_NAME \
		-e SOURCE_LOCATION=$SOURCE_LOCATION \
		-e MAKE_PUBLIC_AMIS=$MAKE_PUBLIC_AMIS \
		-e MAKE_PUBLIC_SNAPSHOTS=$MAKE_PUBLIC_SNAPSHOTS \
		-e AWS_AMI_ORG_ARN=$AWS_AMI_ORG_ARN \
		-e AWS_SNAPSHOT_USER=$AWS_SNAPSHOT_USER \
		--entrypoint="/bin/bash" \
		amazon/aws-cli -c "./aws-copy.sh"
}

build-gc-tar-file() {
	$ENVS \
	GCP_STORAGE_BUNDLE=$GCP_STORAGE_BUNDLE \
	GCP_STORAGE_BUNDLE_LOG=$GCP_STORAGE_BUNDLE_LOG \
	STACK_VERSION=$STACK_VERSION \
	./scripts/bundle-gcp-image.sh
}

build-gc-centos7() {
	METADATA_FILENAME_POSTFIX=$METADATA_FILENAME_POSTFIX
	$ENVS \
	OS=centos7 \
	OS_TYPE=redhat7 \
    GCP_SOURCE_IMAGE=$GCP_SOURCE_IMAGE \
	ATLAS_ARTIFACT_TYPE=google \
	GCP_STORAGE_BUNDLE=$GCP_STORAGE_BUNDLE \
	GCP_STORAGE_BUNDLE_LOG=$GCP_STORAGE_BUNDLE_LOG \
	SALT_INSTALL_OS=centos \
	GIT_REV=$GIT_REV \
	GIT_BRANCH=$GIT_BRANCH \
	GIT_TAG=$GIT_TAG \
	./scripts/packer.sh build -color=false -only=gc-centos7 $PACKER_OPTS
}

build-azure-centos7() {
	$ENVS \
	AZURE_STORAGE_ACCOUNTS=$AZURE_BUILD_STORAGE_ACCOUNT \
	OS=centos7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=azure-arm \
	SALT_INSTALL_OS=centos \
	AZURE_IMAGE_VHD=$AZURE_IMAGE_VHD \
	AZURE_IMAGE_PUBLISHER=$AZURE_IMAGE_PUBLISHER \
	AZURE_IMAGE_OFFER=$AZURE_IMAGE_OFFER \
	AZURE_IMAGE_SKU=$AZURE_IMAGE_SKU \
	BUILD_RESOURCE_GROUP_NAME=$BUILD_RESOURCE_GROUP_NAME \
	PRIVATE_VIRTUAL_NETWORK_WITH_PUBLIC_IP=$PRIVATE_VIRTUAL_NETWORK_WITH_PUBLIC_IP \
	GIT_REV=$GIT_REV \
	GIT_BRANCH=$GIT_BRANCH \
	GIT_TAG=$GIT_TAG \
	./scripts/packer.sh build -color=false -only=arm-centos7 $PACKER_OPTS
	if [ "$AZURE_INITIAL_COPY" = "true" ]; then
		TRACE=1 AZURE_STORAGE_ACCOUNTS=$AZURE_BUILD_STORAGE_ACCOUNT ./scripts/azure-copy.sh
	fi
}

build-azure-redhat7() {
	$ENVS \
	AZURE_STORAGE_ACCOUNTS=$AZURE_BUILD_STORAGE_ACCOUNT \
	OS=redhat7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=azure-arm \
	SALT_INSTALL_OS=redhat \
	AZURE_IMAGE_VHD=$AZURE_IMAGE_VHD \
	AZURE_IMAGE_PUBLISHER=$AZURE_IMAGE_PUBLISHER \
	AZURE_IMAGE_OFFER=$AZURE_IMAGE_OFFER \
	AZURE_IMAGE_SKU=$AZURE_IMAGE_SKU \
	BUILD_RESOURCE_GROUP_NAME=$BUILD_RESOURCE_GROUP_NAME \
	PRIVATE_VIRTUAL_NETWORK_WITH_PUBLIC_IP=$PRIVATE_VIRTUAL_NETWORK_WITH_PUBLIC_IP \
	GIT_REV=$GIT_REV \
	GIT_BRANCH=$GIT_BRANCH \
	GIT_TAG=$GIT_TAG \
	./scripts/packer.sh build -color=false -only=arm-redhat7 $PACKER_OPTS
	if [ "$AZURE_INITIAL_COPY" = "true" ]; then
		TRACE=1 AZURE_STORAGE_ACCOUNTS=$AZURE_BUILD_STORAGE_ACCOUNT ./scripts/azure-copy.sh
	fi
}

generate-aws-centos7-changelog() {
	if [ ! -z "$IMAGE_UUID" ]; then
		if [ ! -z "$SOURCE_IMAGE" ]; then
			$ENVS \
			OS=centos \
			IMAGE_UUID=$IMAGE_UUID \
			SOURCE_IMAGE=$SOURCE_IMAGE \
			AWS_INSTANCE_TYPE=$AWS_INSTANCE_TYPE \
			./scripts/changelog/packer.sh build -color=false -only=aws-centos7 -force $PACKER_OPTS
		fi
	fi
}

generate-aws-redhat8-changelog() {
	if [ ! -z "$IMAGE_UUID" ]; then
		if [ ! -z "$SOURCE_IMAGE" ]; then
			$ENVS \
			OS=redhat8 \
			IMAGE_UUID=$IMAGE_UUID \
			SOURCE_IMAGE=$SOURCE_IMAGE \
			AWS_INSTANCE_TYPE=$AWS_INSTANCE_TYPE \
			./scripts/changelog/packer.sh build -color=false -only=aws-redhat8 -force $PACKER_OPTS
		fi
	fi
}

generate-azure-centos7-changelog() {
	if [ ! -z "$IMAGE_UUID" ]; then
		if [ ! -z "$SOURCE_IMAGE" ]; then
			$ENVS \
			OS=centos \
			IMAGE_UUID=$IMAGE_UUID \
			SOURCE_IMAGE=$SOURCE_IMAGE \
			./scripts/changelog/packer.sh build -color=false -only=arm-centos7 -force $PACKER_OPTS
		fi
	fi
}

generate-azure-redhat8-changelog() {
	if [ -z "$PLAN_NAME" ]; then
		echo "PLAN_NAME parameter is mandatory for azure redhat8 related changelog generation!"
		exit 1
	fi

	if [ ! -z "$IMAGE_UUID" ]; then
		if [ ! -z "$SOURCE_IMAGE" ]; then
			$ENVS \
			OS=redhat8 \
			IMAGE_UUID=$IMAGE_UUID \
			SOURCE_IMAGE=$SOURCE_IMAGE \
			PLAN_NAME=$PLAN_NAME \
			./scripts/changelog/packer.sh build -color=false -only=arm-redhat8 -force $PACKER_OPTS
		fi
	fi
}

generate-gc-centos7-changelog() {
	if [ ! -z "$IMAGE_UUID" ]; then
		if [ ! -z "$SOURCE_IMAGE" ]; then
			$ENVS \
			OS=centos \
			IMAGE_UUID=$IMAGE_UUID \
			SOURCE_IMAGE=$SOURCE_IMAGE \
			GCP_STORAGE_BUNDLE=$GCP_STORAGE_BUNDLE \
			GCP_STORAGE_BUNDLE_LOG=$GCP_STORAGE_BUNDLE_LOG \
			STACK_VERSION=$STACK_VERSION \
			./scripts/changelog/packer.sh build -color=false -only=gc-centos7 -force $PACKER_OPTS
		fi
	fi
}

generate-gc-redhat8-changelog() {
	if [ ! -z "$IMAGE_UUID" ]; then
		if [ ! -z "$SOURCE_IMAGE" ]; then
			$ENVS \
			OS=redhat8 \
			IMAGE_UUID=$IMAGE_UUID \
			SOURCE_IMAGE=$SOURCE_IMAGE \
			GCP_STORAGE_BUNDLE=$GCP_STORAGE_BUNDLE \
			GCP_STORAGE_BUNDLE_LOG=$GCP_STORAGE_BUNDLE_LOG \
			STACK_VERSION=$STACK_VERSION \
			./scripts/changelog/packer.sh build -color=false -only=gc-redhat8 -force $PACKER_OPTS
		fi
	fi
}

get-azure-storage-accounts() {
	AZURE_STORAGE_ACCOUNTS=$AZURE_STORAGE_ACCOUNTS TARGET_LOCATIONS=$TARGET_LOCATIONS ./scripts/get-azure-storage-accounts.sh
}

copy-azure-images() {
	TRACE=1 AZURE_STORAGE_ACCOUNTS=$AZURE_STORAGE_ACCOUNTS AZURE_IMAGE_NAME=$AZURE_IMAGE_NAME ./scripts/azure-copy.sh
}

docker-build-centos79() {
	echo "Building CentOS 7.9 image for YCloud"
	OS=centos7 
	OS_TYPE=redhat7 
	CLOUD_PROVIDER=YARN 
	TAG=centos-79 
	DIR=centos7.9 
	docker-build
}

docker-build-redhat88() {
	echo "Building RHEL 8.8 image for YCloud"
	OS=redhat8
	OS_TYPE=redhat8
	CLOUD_PROVIDER=YARN
	TAG=redhat-88
	DIR=redhat8
	docker-build
}

docker-build-redhat8() {
	echo "Building RHEL 8.10 image for YCloud"
	OS=redhat8
	OS_TYPE=redhat8
	CLOUD_PROVIDER=YARN
	TAG=redhat-8
	DIR=redhat8.10
	docker-build
}

docker-build-yarn-loadbalancer() {
	echo "Building loadbalancer image for YCloud"
	OS=centos7
	OS_TYPE=redhat7
	CLOUD_PROVIDER=YARN
	TAG=yarn-loadbalancer
	DIR=yarn-loadbalancer
	docker-build
}

docker-build() {
	DOCKER_IMAGE_NAME=cloudbreak/$TAG:$(date +%Y-%m-%d-%H-%M-%S)
	DOCKER_ENVS="OS=$OS OS_TYPE=$OS_TYPE ARCHITECTURE=$ARCHITECTURE CLOUD_PROVIDER=$CLOUD_PROVIDER SALT_VERSION=$SALT_VERSION SALT_PATH=$SALT_PATH SALTBOOT_VERSION=$SALTBOOT_VERSION SALTBOOT_HTTPS_ENABLED=$SALTBOOT_HTTPS_ENABLED PYZMQ_VERSION=$PYZMQ_VERSION PYTHON_APT_VERSION=$PYTHON_APT_VERSION TRACE=1 CUSTOM_IMAGE_TYPE=$CUSTOM_IMAGE_TYPE DOCKER_IMAGE_NAME=$DOCKER_IMAGE_NAME DOCKER_REPOSITORY=$DOCKER_REPOSITORY IMAGE_UUID=$IMAGE_UUID TAG=$TAG IMAGE_NAME=$IMAGE_NAME"
	DOCKER_BUILD_ARGS=$(echo $DOCKER_ENVS | xargs -n 1 echo "--build-arg " | xargs)
	docker build $DOCKER_BUILD_ARGS -t $DOCKER_REPOSITORY/$DOCKER_IMAGE_NAME -f docker/$DIR/Dockerfile .
	docker run --rm -v $PWD/docker:/tmp/docker -w /tmp --entrypoint /bin/bash $DOCKER_REPOSITORY/$DOCKER_IMAGE_NAME -c "cp /tmp/manifest.json /tmp/docker/"
	MANIFEST_FILE="$IMAGE_NAME_$METADATA_FILENAME_POSTFIX.json"
	mv "$PWD/docker/manifest.json" $MANIFEST_FILE
	
	DOCKER_IMAGE_NAME=$DOCKER_IMAGE_NAME 
	push-docker-image-to-hwx-registry
}

push-docker-image-to-hwx-registry() {
	docker login --username=$DOCKER_REPO_USERNAME --password=$DOCKER_REPO_PASSWORD $DOCKER_REPOSITORY && docker push $DOCKER_REPOSITORY/$DOCKER_IMAGE_NAME
}

# What is this anyway?!
build-in-docker() {
	docker run -it \
		-v $PWD:$PWD \
		-w $PWD \
		-e ATLAS_TOKEN=$ATLAS_TOKEN \
		-e MOCK=true \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v /usr/local/bin/docker:/usr/local/bin/docker \
		images:build make build-aws
}

cleanup-metadata-repo() {
	rm -rf $(GITHUB_REPO)
}

push-to-metadata-repo() {
	cleanup-metadata-repo
	GITHUB_ORG=$GITHUB_ORG GITHUB_REPO=$GITHUB_REPO CLOUD_PROVIDER=$CLOUD_PROVIDER IMAGE_NAME=$IMAGE_NAME ./scripts/push-to-metadata-repo.sh
	cleanup-metadata-repo
}

upload-package-list() {
	if [ ! "$IMAGE_UUID" = "YARN" ]; then
		if [ ! -z "$IMAGE_NAME" ]; then
			UUID=$(cat $IMAGE_NAME_$METADATA_FILENAME_POSTFIX.json | jq -r '.uuid // empty')
			copy-manifest-to-s3-bucket
		fi
	fi
}

copy-manifest-to-s3-bucket() {
	if [ ! "$IMAGE_UUID" = "YARN" ]; then
		if [ ! -z "$UUID" ]; then
			cp -- installed-delta-packages.csv "$UUID-manifest.csv"
			AWS_DEFAULT_REGION=eu-west-1
			aws s3 cp "$UUID-manifest.csv" s3://cloudbreak-imagecatalog/image-manifests/ --acl public-read
		fi
	fi
}

copy-changelog-to-s3-bucket() {
	if [ ! -z "$IMAGE_UUID_1" ]; then
		if [ ! -z "$IMAGE_UUID_2" ]; then	
			AWS_DEFAULT_REGION=eu-west-1
			aws s3 cp "$IMAGE_UUID_1-to-$IMAGE_UUID_2-changelog.txt" s3://cloudbreak-imagecatalog/image-changelogs/ --acl public-read
		fi
	fi
}

generate-last-metadata-url-file() {
	if [ ! -z "$IMAGE_NAME" ]; then	
		echo "METADATA_URL=https://raw.githubusercontent.com/$GITHUB_ORG/$GITHUB_REPO/master/$IMAGE_NAME_$METADATA_FILENAME_POSTFIX.json" > last_md
		echo IMAGE_NAME=$IMAGE_NAME >> last_md
	else
		# This block remains here for backward compatibility reasons when the IMAGE_NAME is not defined as an env variable
		echo "METADATA_URL=https://raw.githubusercontent.com/$GITHUB_ORG/$GITHUB_REPO/master/$(ls -1tr *_manifest.json | tail -1 | sed 's/_manifest//')" > last_md
		echo "IMAGE_NAME=$(ls -1tr *_manifest.json | tail -1 | sed 's/_.*_manifest.json//')" >> last_md
	fi
}

generate-image-properties() {
	BASE_NAME=$BASE_NAME STACK_TYPE=$STACK_TYPE STACK_VERSION=$STACK_VERSION ./scripts/generate-image-properties.sh
}

check-image-regions() {
	AWS_AMI_REGIONS="$AWS_AMI_REGIONS_ALL" \
	AZURE_STORAGE_ACCOUNTS="$AZURE_STORAGE_ACCOUNTS_ALL" \
	CLOUD_PROVIDER=$CLOUD_PROVIDER \
	OS=$OS \
	IMAGE_REGIONS="$IMAGE_REGIONS" \
	./scripts/check-image-regions.sh
}

# The method's name must be provided as the only parameter to simulate how the Makefile used to work
if [ ! -z $1 ]; then

	setenvs
	$1
fi
