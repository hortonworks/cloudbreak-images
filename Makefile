BASE_NAME ?= cb
DESCRIPTION ?= "Official Cloudbreak image"
STACK_VERSION ?= ""
ATLAS_PROJECT ?= "cloudbreak"
ENABLE_POSTPROCESSORS ?= ""
CUSTOM_IMAGE_TYPE ?= "hortonworks"
IMAGE_OWNER ?= "cloudbreak-dev@cloudera.com"
#for oracle JDK use oracle-java
OPTIONAL_STATES ?= ""
# only for oracle JDK
ORACLE_JDK8_URL_RPM ?= ""
SLES_REGISTRATION_CODE ?= "73D5EBB68CB348"

# Azure VM image specifications
ifeq ($(CLOUD_PROVIDER),Azure)
	PRIVATE_VIRTUAL_NETWORK_WITH_PUBLIC_IP ?= false
	AZURE_INITIAL_COPY ?= true

	ifdef BUILD_RESOURCE_GROUP_NAME
		ifdef ARM_BUILD_REGION
$(error BUILD_RESOURCE_GROUP_NAME and ARM_BUILD_REGION should not be set together)
		endif
	else
		ARM_BUILD_REGION ?= northeurope
	endif

	ifdef AZURE_IMAGE_VHD
		AZURE_IMAGE_MARKETPLACE_SET = false
		ifdef AZURE_IMAGE_PUBLISHER
			AZURE_IMAGE_MARKETPLACE_SET = true
		endif
		ifdef AZURE_IMAGE_OFFER
			AZURE_IMAGE_MARKETPLACE_SET = true
		endif
		ifdef AZURE_IMAGE_SKU
			AZURE_IMAGE_MARKETPLACE_SET = true
		endif
		ifeq ($(AZURE_IMAGE_MARKETPLACE_SET),true)
$(error "AZURE_IMAGE_VHD and Marketplace image properties (AZURE_IMAGE_PUBLISHER, AZURE_IMAGE_OFFER, AZURE_IMAGE_SKU) should not be set together")
		endif
	else
		ifeq ($(OS),redhat7)
			AZURE_IMAGE_PUBLISHER ?= RedHat
			AZURE_IMAGE_OFFER ?= RHEL
			AZURE_IMAGE_SKU ?= 7_9
		else ifeq ($(OS),centos7)
			AZURE_IMAGE_PUBLISHER ?= OpenLogic
			AZURE_IMAGE_OFFER ?= CentOS
			AZURE_IMAGE_SKU ?= 7.6
		else ifdef OS
$(error Unexpected OS type $(OS) for Azure)
		endif
	endif
endif

DOCKER_REPOSITORY ?= docker-sandbox.infra.cloudera.com
DOCKER_REPO_USERNAME ?= ""
DOCKER_REPO_PASSWORD ?= ""

# This needs to be changed if there is a version change in fluent components. See usage in the salt files in the Cloudbreak repo.
# Deprecated: do not increase it anymore, but it can be removed only if no images in use with date before this line is committed.
FLUENT_PREWARM_TAG ?= "fluent_prewarmed_v5"
# This needs to be changed if there is a version change in metering heartbeat component. See usage in the salt files in the Cloudbreak repo.
METERING_PREWARM_TAG ?= "metering_prewarmed_v3"
# This needs to be changed if there is a version change in cdp-telemetry cli component. See usage in the salt files in the Cloudbreak repo.
# Deprecated: do not increase it anymore, but it can be removed only if no images in use with date before this line is committed.
CDP_TELEMETRY_PREWARM_TAG ?= "cdp_telemetry_prewarmed_v12"
# This needs to be changed if there is a version change in components other than fluent, or if there are relevant changes to the salt scripts in Cloudbreak.
PREWARM_TAG ?= "prewarmed_v1"

###############################
# DO NOT EDIT BELOW THIS LINE #
###############################

## https://github.com/hashicorp/packer/issues/6536
AWS_MAX_ATTEMPTS ?= 300
PACKAGE_VERSIONS ?= ""
SALT_VERSION ?= 3000.8
SALT_PATH ?= /opt/salt_$(SALT_VERSION)
PYZMQ_VERSION ?= 19.0
PYTHON_APT_VERSION ?= 1.1.0_beta1ubuntu0.16.04.1

# This block remains here for backward compatibility reasons when the IMAGE_NAME is not defined as an env variable
ifndef IMAGE_NAME
	STACK_VERSION_SHORT=$(STACK_TYPE)-$(shell echo $(STACK_VERSION) | tr -d . | cut -c1-4 )
	export IMAGE_NAME := $(BASE_NAME)-$(shell echo $(STACK_VERSION_SHORT) | tr '[:upper:]' '[:lower:]')-$(shell date +%s)$(IMAGE_NAME_SUFFIX)
@echo IMAGE_NAME was not defined as an environment variable. Generated value: $(IMAGE_NAME)
endif

ifeq ($(OS),centos7)
	IMAGE_SIZE ?= 30
else
	IMAGE_SIZE ?= 64
endif

ifdef MAKE_PUBLIC_SNAPSHOTS
	AWS_SNAPSHOT_GROUPS = "all"
endif

ifdef MAKE_PUBLIC_AMIS
	AWS_AMI_GROUPS = "all"
endif

TAG_CUSTOMER_DELIVERED ?= "No"
INCLUDE_FLUENT ?= "Yes"
INCLUDE_CDP_TELEMETRY ?= "Yes"
INCLUDE_METERING ?= "Yes"

CDP_TELEMETRY_VERSION ?= ""
CDP_LOGGING_AGENT_VERSION ?= ""

ifndef JUMPGATE_AGENT_RPM_URL
	JUMPGATE_AGENT_RPM_URL="https://cloudera-build-us-west-1.vpc.cloudera.com/s3/build/17606589/inverting-proxy/2.x/redhat7/yum/tars/inverting-proxy/jumpgate-agent.rpm"
endif

ENVS=METADATA_FILENAME_POSTFIX=$(METADATA_FILENAME_POSTFIX) DESCRIPTION=$(DESCRIPTION) STACK_TYPE=$(STACK_TYPE) MPACK_URLS=$(MPACK_URLS) HDP_VERSION=$(HDP_VERSION) BASE_NAME=$(BASE_NAME) IMAGE_NAME=$(IMAGE_NAME) IMAGE_SIZE=$(IMAGE_SIZE) INCLUDE_CDP_TELEMETRY=$(INCLUDE_CDP_TELEMETRY) INCLUDE_FLUENT=$(INCLUDE_FLUENT) INCLUDE_METERING=$(INCLUDE_METERING) ENABLE_POSTPROCESSORS=$(ENABLE_POSTPROCESSORS) CUSTOM_IMAGE_TYPE=$(CUSTOM_IMAGE_TYPE) OPTIONAL_STATES=$(OPTIONAL_STATES) ORACLE_JDK8_URL_RPM=$(ORACLE_JDK8_URL_RPM) PREINSTALLED_JAVA_HOME=${PREINSTALLED_JAVA_HOME} IMAGE_OWNER=${IMAGE_OWNER} REPOSITORY_TYPE=${REPOSITORY_TYPE} PACKAGE_VERSIONS=$(PACKAGE_VERSIONS) SALT_VERSION=$(SALT_VERSION) SALT_PATH=$(SALT_PATH) PYZMQ_VERSION=$(PYZMQ_VERSION) PYTHON_APT_VERSION=$(PYTHON_APT_VERSION) AWS_MAX_ATTEMPTS=$(AWS_MAX_ATTEMPTS) TRACE=1 AWS_SNAPSHOT_GROUPS=$(AWS_SNAPSHOT_GROUPS) AWS_AMI_GROUPS=$(AWS_AMI_GROUPS) TAG_CUSTOMER_DELIVERED=$(TAG_CUSTOMER_DELIVERED) VERSION=$(VERSION) PARCELS_NAME=$(PARCELS_NAME) PARCELS_ROOT=$(PARCELS_ROOT) SUBNET_ID=$(SUBNET_ID) VPC_ID=$(VPC_ID) VIRTUAL_NETWORK_RESOURCE_GROUP_NAME=$(VIRTUAL_NETWORK_RESOURCE_GROUP_NAME) ARM_BUILD_REGION=$(ARM_BUILD_REGION) PRE_WARM_PARCELS=$(PRE_WARM_PARCELS) PRE_WARM_CSD=$(PRE_WARM_CSD) SLES_REGISTRATION_CODE=$(SLES_REGISTRATION_CODE) FLUENT_PREWARM_TAG=$(FLUENT_PREWARM_TAG) METERING_PREWARM_TAG=$(METERING_PREWARM_TAG) CDP_TELEMETRY_PREWARM_TAG=$(CDP_TELEMETRY_PREWARM_TAG) PREWARM_TAG=$(PREWARM_TAG)

GITHUB_ORG ?= hortonworks
GITHUB_REPO ?= cloudbreak-images-metadata

# it testing, atlas uploads should go to mocking artifact slush
#PACKER_VARS=
GIT_REV=$(shell git rev-parse --short HEAD)
GIT_BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
GIT_TAG=$(shell git describe --exact-match --tags 2>/dev/null)

ifdef DOCKER_VERSION
	PACKER_VARS+=-var yum_version_docker=$(DOCKER_VERSION)
endif

ifeq ($(MOCK),true)
	PACKER_OPTS=$(PACKER_VARS) -var atlas_artifact=mock
else
	PACKER_OPTS+=$(PACKER_VARS)
endif

ifeq ($(CUSTOM_IMAGE_TYPE),freeipa)
	BASE_NAME=freeipa
endif

GCP_STORAGE_BUNDLE ?= cloudera-$(BASE_NAME)-images
GCP_STORAGE_BUNDLE_LOG ?= cloudera-$(BASE_NAME)-images

define GCP_AMI_REGIONS
asia-east1,asia-east2,australia-southeast1,europe-west2,europe-west3,europe-west4,us-west2,southamerica-east1,asia-southeast1,us-central1,europe-west1,europe-north1,us-west1,northamerica-northeast1,us-east4,asia-south1,us-east1,asia-northeast1,asia-southeast2
endef

ifndef AWS_AMI_REGIONS
define AWS_AMI_REGIONS
ap-northeast-1,ap-northeast-2,ap-south-1,ap-southeast-1,ap-southeast-2,ca-central-1,eu-central-1,eu-west-1,eu-west-2,eu-west-3,sa-east-1,us-east-1,us-east-2,us-west-1,us-west-2,eu-north-1,eu-south-1,af-south-1,me-south-1
endef
endif

ifndef AZURE_STORAGE_ACCOUNTS
define AZURE_STORAGE_ACCOUNTS
East Asia:cldreastasia,\
East US:cldreastus,\
Central US:cldrcentralus,\
North Europe:cldrnortheurope,\
South Central US:cldrsouthcentralus,\
North Central US:cldrnorthcentralus,\
East US 2:cldreastus2,\
Japan East:cldrjapaneast,\
Japan West:cldrjapanwest,\
South East Asia:cldrsoutheastasia,\
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
Norway East:cldrnorwayeast
endef
endif

AZURE_BUILD_STORAGE_ACCOUNT ?= "West US 2:cldrwestus2"

S3_TARGET ?= "s3://public-repo-1.hortonworks.com/HDP/cloudbreak"

show-image-name:
	@echo IMAGE_NAME=$(IMAGE_NAME)

build-aws-centos7-base:
	$(ENVS) \
	AWS_AMI_REGIONS="us-west-1" \
	OS=centos7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=centos \
	GIT_REV=$(GIT_REV) \
	GIT_BRANCH=$(GIT_BRANCH) \
	GIT_TAG=$(GIT_TAG) \
	./scripts/packer.sh build -only=aws-centos7 $(PACKER_OPTS)

build-aws-centos7:
	@ METADATA_FILENAME_POSTFIX=$(METADATA_FILENAME_POSTFIX) make build-aws-centos7-base
	$(ENVS) \
	AWS_AMI_REGIONS="$(AWS_AMI_REGIONS)" \
	GIT_REV=$(GIT_REV) \
	GIT_BRANCH=$(GIT_BRANCH) \
	GIT_TAG=$(GIT_TAG) \
	./scripts/sparseimage/packer.sh build -force $(PACKER_OPTS)

copy-aws-images:
	docker run -i --rm \
		-v "${PWD}/scripts:/scripts" \
		-w /scripts \
		-e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
		-e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
		-e AWS_AMI_REGIONS=$(AWS_AMI_REGIONS) \
		-e IMAGE_NAME=$(IMAGE_NAME) \
		-e SOURCE_LOCATION=$(SOURCE_LOCATION) \
		--entrypoint="/bin/bash" \
		amazon/aws-cli -c "./aws-copy.sh"

build-gc-tar-file:
	$(ENVS) \
	GCP_AMI_REGIONS=$(GCP_AMI_REGIONS) \
	GCP_STORAGE_BUNDLE=$(GCP_STORAGE_BUNDLE) \
	GCP_STORAGE_BUNDLE_LOG=$(GCP_STORAGE_BUNDLE_LOG) \
	./scripts/bundle-gcp-image.sh

build-gc-centos7:
	@ METADATA_FILENAME_POSTFIX=$(METADATA_FILENAME_POSTFIX)
	$(ENVS) \
	OS=centos7 \
	OS_TYPE=redhat7 \
	GCP_AMI_REGIONS=$(GCP_AMI_REGIONS) \
	GCP_STORAGE_BUNDLE=$(GCP_STORAGE_BUNDLE) \
	GCP_STORAGE_BUNDLE_LOG=$(GCP_STORAGE_BUNDLE_LOG) \
	SALT_INSTALL_OS=centos \
	GIT_REV=$(GIT_REV) \
	GIT_BRANCH=$(GIT_BRANCH) \
	GIT_TAG=$(GIT_TAG) \
	./scripts/packer.sh build -only=gc-centos7 $(PACKER_OPTS)

build-azure-centos7:
	$(ENVS) \
	AZURE_STORAGE_ACCOUNTS=$(AZURE_BUILD_STORAGE_ACCOUNT) \
	OS=centos7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=azure-arm \
	SALT_INSTALL_OS=centos \
	AZURE_IMAGE_VHD=$(AZURE_IMAGE_VHD) \
	AZURE_IMAGE_PUBLISHER=$(AZURE_IMAGE_PUBLISHER) \
	AZURE_IMAGE_OFFER=$(AZURE_IMAGE_OFFER) \
	AZURE_IMAGE_SKU=$(AZURE_IMAGE_SKU) \
	BUILD_RESOURCE_GROUP_NAME=$(BUILD_RESOURCE_GROUP_NAME) \
	PRIVATE_VIRTUAL_NETWORK_WITH_PUBLIC_IP=$(PRIVATE_VIRTUAL_NETWORK_WITH_PUBLIC_IP) \
	GIT_REV=$(GIT_REV) \
	GIT_BRANCH=$(GIT_BRANCH) \
	GIT_TAG=$(GIT_TAG) \
	./scripts/packer.sh build -only=arm-centos7 $(PACKER_OPTS)
ifeq ($(AZURE_INITIAL_COPY),true)
	TRACE=1 AZURE_STORAGE_ACCOUNTS=$(AZURE_BUILD_STORAGE_ACCOUNT) ./scripts/azure-copy.sh
endif

build-azure-redhat7:
	$(ENVS) \
	AZURE_STORAGE_ACCOUNTS=$(AZURE_BUILD_STORAGE_ACCOUNT) \
	OS=redhat7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=azure-arm \
	SALT_INSTALL_OS=redhat \
	AZURE_IMAGE_VHD=$(AZURE_IMAGE_VHD) \
	AZURE_IMAGE_PUBLISHER=$(AZURE_IMAGE_PUBLISHER) \
	AZURE_IMAGE_OFFER=$(AZURE_IMAGE_OFFER) \
	AZURE_IMAGE_SKU=$(AZURE_IMAGE_SKU) \
	BUILD_RESOURCE_GROUP_NAME=$(BUILD_RESOURCE_GROUP_NAME) \
	PRIVATE_VIRTUAL_NETWORK_WITH_PUBLIC_IP=$(PRIVATE_VIRTUAL_NETWORK_WITH_PUBLIC_IP) \
	GIT_REV=$(GIT_REV) \
	GIT_BRANCH=$(GIT_BRANCH) \
	GIT_TAG=$(GIT_TAG) \
	./scripts/packer.sh build -only=arm-redhat7 $(PACKER_OPTS)
ifeq ($(AZURE_INITIAL_COPY),true)
	TRACE=1 AZURE_STORAGE_ACCOUNTS=$(AZURE_BUILD_STORAGE_ACCOUNT) ./scripts/azure-copy.sh
endif

copy-azure-images:
	TRACE=1 AZURE_STORAGE_ACCOUNTS="$(AZURE_STORAGE_ACCOUNTS)" AZURE_IMAGE_NAME="$(AZURE_IMAGE_NAME)" ./scripts/azure-copy.sh

docker-build-centos7:
	@ OS=centos7 OS_TYPE=redhat7 TAG=centos-7 DIR=centos7.3 make docker-build

docker-build-centos74:
	echo "Building image for ycloud2"
	@ OS=centos7 OS_TYPE=redhat7 TAG=centos-74 DIR=centos7.4 make docker-build

docker-build-centos75:
	echo "Building image for ycloud2"
	@ OS=centos7 OS_TYPE=redhat7 TAG=centos-75 DIR=centos7.5 make docker-build

docker-build-centos76:
	echo "Building image for ycloud2"
	@ OS=centos7 OS_TYPE=redhat7 TAG=centos-76 DIR=centos7.6 make docker-build

docker-build-yarn-loadbalancer:
	echo "Building loadbalancer image for ycloud2"
	@ OS=centos7 OS_TYPE=redhat7 TAG=yarn-loadbalancer DIR=yarn-loadbalancer make docker-build

docker-build:
	$(eval DOCKER_ENVS="OS=$(OS) OS_TYPE=$(OS_TYPE) SALT_VERSION=$(SALT_VERSION) SALT_PATH=$(SALT_PATH) PYZMQ_VERSION=$(PYZMQ_VERSION) PYTHON_APT_VERSION=$(PYTHON_APT_VERSION) TRACE=1")
	$(eval DOCKER_BUILD_ARGS=$(shell echo ${DOCKER_ENVS} | xargs -n 1 echo "--build-arg " | xargs))
	$(eval IMAGE_NAME=cloudbreak/${TAG}:$(shell date +%Y-%m-%d-%H-%M-%S))
	docker build $(DOCKER_BUILD_ARGS) -t $(DOCKER_REPOSITORY)/${IMAGE_NAME} -f docker/${DIR}/Dockerfile .
	make IMAGE_NAME=${IMAGE_NAME} push-docker-image-to-hwx-registry

push-docker-image-to-hwx-registry:
	docker login --username=$(DOCKER_REPO_USERNAME) --password=$(DOCKER_REPO_PASSWORD) $(DOCKER_REPOSITORY) && docker push $(DOCKER_REPOSITORY)/${IMAGE_NAME}

build-in-docker:
	docker run -it \
		-v $(PWD):$(PWD) \
		-w $(PWD) \
		-e ATLAS_TOKEN=$(ATLAS_TOKEN) \
		-e MOCK=true \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v /usr/local/bin/docker:/usr/local/bin/docker \
		images:build make build-aws

list-amz-linux-amis:
	aws ec2 describe-images --filter Name=owner-alias,Values=amazon --query 'reverse(sort_by(Images[?contains(ImageLocation,`amazon/amzn-ami-hvm`) && ends_with(ImageLocation, `gp2`)].{loc:ImageLocation,id:ImageId}, &loc))' --out table --region us-west-2

latest-amz-linux-ami:
	aws ec2 describe-images --filter Name=owner-alias,Values=amazon --query 'reverse(sort_by(Images[?contains(ImageLocation,`amazon/amzn-ami-hvm`) && ends_with(ImageLocation, `gp2`)].{loc:ImageLocation,id:ImageId}, &loc))[0].id' --out text --region us-west-2

cleanup-metadata-repo:
	rm -rf $(GITHUB_REPO)

push-to-metadata-repo: cleanup-metadata-repo
	git clone git@github.com:$(GITHUB_ORG)/$(GITHUB_REPO).git
	$(eval FILE=$(shell (ls -1tr *_manifest.json | tail -1 | sed "s/_manifest//")))
	cp $(FILE) $(GITHUB_REPO)
	$(eval UUID=$(shell (cat $(FILE) | jq .uuid)))
	mkdir -p "${GITHUB_REPO}/manifest" && cp installed-delta-packages.csv "${GITHUB_REPO}/manifest/${UUID}-manifest.csv"
	cd $(GITHUB_REPO) && git add -A && git commit -am"Upload new metadata file" && git push
	make cleanup-metadata-repo

generate-last-metadata-url-file:
ifdef IMAGE_NAME
	echo "METADATA_URL=https://raw.githubusercontent.com/$(GITHUB_ORG)/$(GITHUB_REPO)/master/$(IMAGE_NAME)_$(METADATA_FILENAME_POSTFIX).json" > last_md
	echo IMAGE_NAME=$(IMAGE_NAME) >> last_md
else
# This block remains here for backward compatibility reasons when the IMAGE_NAME is not defined as an env variable
	echo "METADATA_URL=https://raw.githubusercontent.com/$(GITHUB_ORG)/$(GITHUB_REPO)/master/$(shell (ls -1tr *_manifest.json | tail -1 | sed "s/_manifest//"))" > last_md
	echo "IMAGE_NAME=$(shell (ls -1tr *_manifest.json | tail -1 | sed "s/_.*_manifest.json//"))" >> last_md
endif

generate-image-properties:
	BASE_NAME=$(BASE_NAME) \
	STACK_TYPE=$(STACK_TYPE) \
	STACK_VERSION=$(STACK_VERSION) \
	./scripts/generate-image-properties.sh
