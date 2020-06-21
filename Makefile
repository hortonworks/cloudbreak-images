BASE_NAME ?= cb
DESCRIPTION ?= "Official Cloudbreak image"
STACK_TYPE ?= "CDH"
STACK_VERSION ?= "7.2.0"
STACK_BASEURL=http://cloudera-build-us-west-1.vpc.cloudera.com/s3/build/3425821/cdh/7.x/parcels/
STACK_REPOID=CDH-7.2.0
STACK_REPOSITORY_VERSION=CDH-7.2.0-1.cdh7.2.0.p0.3425821
PARCELS_NAME=CDH-7.2.0-1.cdh7.2.0.p0.3425821-el7.parcel
PARCELS_ROOT=/opt/cloudera/parcels
STACK_BUILD_NUMBER=3425821


CLUSTERMANAGER_VERSION=7.2.0
CLUSTERMANAGER_BASEURL=http://cloudera-build-us-west-1.vpc.cloudera.com/s3/build/3341661/cm7/7.2.0/redhat7/yum/
CLUSTERMANAGER_GPGKEY=http://cloudera-build-us-west-1.vpc.cloudera.com/s3/build/3341661/cm7/7.2.0/redhat7/yum/RPM-GPG-KEY-cloudera
CM_BUILD_NUMBER=3341661
PRE_WARM_PARCELS="[ [\\"PROFILER_MANAGER-2.0.3.2.0.3.0-67-el7.parcel\\",\\"http://s3.amazonaws.com/dev.hortonworks.com/DSS/centos7/2.x/BUILDS/2.0.3.0-67/tars/dataplane_profilers\\"], [\\"PROFILER_SCHEDULER-2.0.3.2.0.3.0-67-el7.parcel\\",\\"http://s3.amazonaws.com/dev.hortonworks.com/DSS/centos7/2.x/BUILDS/2.0.3.0-67/tars/dataplane_profilers\\"], [\\"SPARK3-3.0.0.2.99.7110.0-18-1.p0.3525631-el7.parcel\\",\\"http://cloudera-build-us-west-1.vpc.cloudera.com/s3/build/3525631/spark3/2.x/parcels\\"], [\\"FLINK-1.10.0-csa1.2.1.0-cdh7.2.0.0-233-3770051-el7.parcel\\",\\"http://cloudera-build-us-west-1.vpc.cloudera.com/s3/build/3770051/csa/1.2.1.0/parcels\\"], [\\"CFM-2.0.0.0-el7.parcel\\",\\"http://s3.amazonaws.com/dev.hortonworks.com/CFM/centos7/2.x/BUILDS/2.0.0.0-213/tars/parcel\\"]]"
PRE_WARM_CSD="[\\"http://s3.amazonaws.com/dev.hortonworks.com/DSS/centos7/2.x/BUILDS/2.0.3.0-67/tars/dataplane_profilers/PROFILER_MANAGER-2.0.3.2.0.3.0-67.jar\\", \\"http://s3.amazonaws.com/dev.hortonworks.com/DSS/centos7/2.x/BUILDS/2.0.3.0-67/tars/dataplane_profilers/PROFILER_SCHEDULER-2.0.3.2.0.3.0-67.jar\\", \\"http://s3.amazonaws.com/dev.hortonworks.com/CFM/centos7/2.x/BUILDS/2.0.0.0-213/tars/parcel/NIFI-1.11.4.2.0.0.0-213.jar\\", \\"http://s3.amazonaws.com/dev.hortonworks.com/CFM/centos7/2.x/BUILDS/2.0.0.0-213/tars/parcel/NIFICA-1.11.4.2.0.0.0-213.jar\\", \\"http://cloudera-build-us-west-1.vpc.cloudera.com/s3/build/3525631/spark3/2.x/csd/SPARK3_ON_YARN-3.0.0.2.99.7110.0-18.jar\\", \\"http://cloudera-build-us-west-1.vpc.cloudera.com/s3/build/3770051/csa/1.2.1.0/csd/FLINK-1.10.0-csa1.2.1.0-cdh7.2.0.0-233-3770051.jar\\", \\"http://s3.amazonaws.com/dev.hortonworks.com/CFM/centos7/2.x/BUILDS/2.0.0.0-213/tars/parcel/NIFIREGISTRY-0.5.0.2.0.0.0-213.jar\\"]"
CFM_BUILD_NUMBER=2.0.0.0-213
PROFILER_BUILD_NUMBER=2.0.3.0-67
SPARK3_BUILD_NUMBER=2.99.7110.0-18
CSA_BUILD_NUMBER=1.2.1.0-23


ATLAS_PROJECT ?= "cloudbreak"
ENABLE_POSTPROCESSORS ?= ""
CUSTOM_IMAGE_TYPE ?= "hortonworks"
IMAGE_OWNER ?= "sseth@cloudera.com"
#for oracle JDK use oracle-java
OPTIONAL_STATES ?= ""
# only for oracle JDK
ORACLE_JDK8_URL_RPM ?= ""
SLES_REGISTRATION_CODE ?= "73D5EBB68CB348"

# Azure VM image specifications
AZURE_IMAGE_PUBLISHER ?= OpenLogic
AZURE_IMAGE_OFFER ?= CentOS
AZURE_IMAGE_SKU ?= 7.6
ARM_BUILD_REGION ?= northeurope

DOCKER_REPOSITORY ?= registry.eng.hortonworks.com
DOCKER_REPO_USERNAME ?= ""
DOCKER_REPO_PASSWORD ?= ""


###############################
# DO NOT EDIT BELOW THIS LINE #
###############################

## https://github.com/hashicorp/packer/issues/6536
AWS_MAX_ATTEMPTS ?= 300
PACKAGE_VERSIONS ?= ""
SALT_VERSION ?= 3000.2
SALT_PATH ?= /opt/salt_$(SALT_VERSION)
PYZMQ_VERSION ?= 19.0
PYTHON_APT_VERSION ?= 1.1.0_beta1ubuntu0.16.04.1
STACK_VERSION_SHORT=$(STACK_TYPE)-$(shell echo $(STACK_VERSION) | tr -d . | cut -c1-2 )
ifndef IMAGE_NAME
	IMAGE_NAME ?= $(BASE_NAME)-$(shell echo $(STACK_VERSION_SHORT) | tr '[:upper:]' '[:lower:]')-$(shell date +%y%m%d%H%M)$(IMAGE_NAME_SUFFIX)
endif

IMAGE_SIZE ?= 30

ifdef MAKE_PUBLIC_SNAPSHOTS
	AWS_SNAPSHOT_GROUPS = "all"
endif

ifdef MAKE_PUBLIC_AMIS
	AWS_AMI_GROUPS = "all"
endif

TAG_CUSTOMER_DELIVERED ?= "No"
INCLUDE_FLUENT ?= "Yes"
INCLUDE_METERING ?= "Yes"

METADATA_FILENAME_POSTFIX ?= $(shell date +%s)

ENVS=METADATA_FILENAME_POSTFIX=$(METADATA_FILENAME_POSTFIX) DESCRIPTION=$(DESCRIPTION) STACK_TYPE=$(STACK_TYPE) MPACK_URLS=$(MPACK_URLS) HDP_VERSION=$(HDP_VERSION) BASE_NAME=$(BASE_NAME) IMAGE_NAME=$(IMAGE_NAME) IMAGE_SIZE=$(IMAGE_SIZE) INCLUDE_FLUENT=$(INCLUDE_FLUENT) INCLUDE_METERING=$(INCLUDE_METERING) ENABLE_POSTPROCESSORS=$(ENABLE_POSTPROCESSORS) CUSTOM_IMAGE_TYPE=$(CUSTOM_IMAGE_TYPE) OPTIONAL_STATES=$(OPTIONAL_STATES) ORACLE_JDK8_URL_RPM=$(ORACLE_JDK8_URL_RPM) PREINSTALLED_JAVA_HOME=${PREINSTALLED_JAVA_HOME} IMAGE_OWNER=${IMAGE_OWNER} REPOSITORY_TYPE=${REPOSITORY_TYPE} PACKAGE_VERSIONS=$(PACKAGE_VERSIONS) SALT_VERSION=$(SALT_VERSION) SALT_PATH=$(SALT_PATH) PYZMQ_VERSION=$(PYZMQ_VERSION) PYTHON_APT_VERSION=$(PYTHON_APT_VERSION) AWS_MAX_ATTEMPTS=$(AWS_MAX_ATTEMPTS) TRACE=1 AWS_SNAPSHOT_GROUPS=$(AWS_SNAPSHOT_GROUPS) AWS_AMI_GROUPS=$(AWS_AMI_GROUPS) TAG_CUSTOMER_DELIVERED=$(TAG_CUSTOMER_DELIVERED) VERSION=$(VERSION) PARCELS_NAME=$(PARCELS_NAME) PARCELS_ROOT=$(PARCELS_ROOT) SUBNET_ID=$(SUBNET_ID) VPC_ID=$(VPC_ID) VIRTUAL_NETWORK_RESOURCE_GROUP_NAME=$(VIRTUAL_NETWORK_RESOURCE_GROUP_NAME) ARM_BUILD_REGION=$(ARM_BUILD_REGION) PRE_WARM_PARCELS=$(PRE_WARM_PARCELS) PRE_WARM_CSD=$(PRE_WARM_CSD) SLES_REGISTRATION_CODE=$(SLES_REGISTRATION_CODE)

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

define AWS_AMI_REGIONS
us-west-1,us-west-2
endef

define AWS_GOV_AMI_REGIONS
us-gov-west-1
endef

define AWS_GOV_INSTANCE_PROFILE
packer
endef

define AZURE_STORAGE_ACCOUNTS
East Asia:sequenceiqeastasia2,\
East US:sequenceiqeastus12,\
Central US:sequenceiqcentralus2,\
North Europe:sequenceiqnortheurope2,\
South Central US:sequenceiqouthcentralus2,\
North Central US:sequenceiqorthcentralus2,\
East US 2:sequenceiqeastus22,\
Japan East:sequenceiqjapaneast2,\
Japan West:sequenceiqjapanwest2,\
South East Asia:sequenceiqsoutheastasia2,\
West US:sequenceiqwestus2,\
West Europe:sequenceiqwesteurope2,\
Brazil South:sequenceiqbrazilsouth2,\
Canada East:sequenceiqcanadaeast,\
Canada Central:sequenceiqcanadacentral,\
Australia East:hwxaustraliaeast,\
Australia Southeast:hwxaustralisoutheast,\
Central India:hwxcentralindia,\
Korea Central:hwxkoreacentral,\
Korea South:hwxkoreasouth,\
South India:hwxsouthindia,\
UK South:hwxsouthuk,\
West Central US:hwxwestcentralus,\
UK West:hwxwestuk,\
West US 2:hwxwestus2,\
West India:hwxwestindia,\
Australia Central:hwxaustraliacentral,\
UAE North:hwxuaenorth,\
UAE Central:hwxuaecentral,\
South Africa North:hwxsouthafricanorth,\
South Africa West:hwxsouthafricawest,\
France Central:hwxfrancecentral,\
Switzerland North:hwxswitzerlandnorth,\
Switzerland West:hwxswitzerlandwest,\
Germany North :hwxgermanynorth,\
Germany West Central:hwxgermanywestcentral,\
Norway West:hwxnorwaywest,\
Norway East:hwxnorwayeast
endef

GCP_STORAGE_BUNDLE ?= "sequenceiqimage"
GCP_STORAGE_BUNDLE_LOG ?= "sequenceiqimagelog"

S3_TARGET ?= "s3://public-repo-1.hortonworks.com/HDP/cloudbreak"

show-image-name:
	@echo IMAGE_NAME=$(IMAGE_NAME)

build-aws-amazonlinux:
	$(ENVS) \
	AWS_AMI_REGIONS="$(AWS_AMI_REGIONS)" \
	AWS_INSTANCE_PROFILE="$(AWS_GOV_INSTANCE_PROFILE)" \
	OS=amazonlinux \
	OS_TYPE=redhat6 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=amazon \
	SALT_REPO_FILE="salt-repo-amzn.repo" \
	./scripts/packer.sh build -only=aws-amazonlinux $(PACKER_OPTS)

build-gov-aws-amazonlinux:
	$(ENVS) \
	AWS_AMI_REGIONS="$(AWS_GOV_AMI_REGIONS)" \
	OS=amazonlinux \
	OS_TYPE=redhat6 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=amazon \
	SALT_REPO_FILE="salt-repo-amzn.repo" \
	./scripts/packer.sh build -only=gov-aws-amazonlinux $(PACKER_OPTS)

build-aws-amazonlinux2:
	$(ENVS) \
	AWS_AMI_REGIONS="$(AWS_AMI_REGIONS)" \
	OS=amazonlinux2 \
	OS_TYPE=amazonlinux2 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=amazon \
	./scripts/packer.sh build -only=aws-amazonlinux2 $(PACKER_OPTS)

build-aws-centos6:
	$(ENVS) \
	AWS_AMI_REGIONS="$(AWS_AMI_REGIONS)" \
	OS=centos6 \
	OS_TYPE=redhat6 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=centos \
	SALT_REPO_FILE="salt-repo-el6.repo" \
	./scripts/packer.sh build -only=aws-centos6 $(PACKER_OPTS)

build-aws-centos7-base:
	$(ENVS) \
	AWS_AMI_REGIONS="us-west-1" \
	OS=centos7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=centos \
	./scripts/packer.sh build -only=aws-centos7 $(PACKER_OPTS)

build-aws-redhat7:
	$(ENVS) \
	AWS_AMI_REGIONS="$(AWS_AMI_REGIONS)" \
	OS=redhat7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=redhat \
	./scripts/packer.sh build -only=aws-rhel7 $(PACKER_OPTS)

build-aws-sles12sp3:
	$(ENVS) \
	AWS_AMI_REGIONS="$(AWS_AMI_REGIONS)" \
	OS=sles12 \
	OS_TYPE=sles12 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=suse \
	./scripts/packer.sh build -only=aws-sles12sp3 $(PACKER_OPTS)

build-aws-ubuntu16:
	$(ENVS) \
	AWS_AMI_REGIONS="$(AWS_AMI_REGIONS)" \
	OS=ubuntu16 \
	OS_TYPE=ubuntu16 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=ubuntu \
	./scripts/packer.sh build -only=aws-ubuntu16 $(PACKER_OPTS)

build-aws-centos7: export IMAGE_NAME := $(IMAGE_NAME)

build-aws-centos7: 
	@ METADATA_FILENAME_POSTFIX=$(METADATA_FILENAME_POSTFIX) make build-aws-centos7-base
	$(ENVS) \
	AWS_AMI_REGIONS="$(AWS_AMI_REGIONS)" \
	./scripts/sparseimage/packer.sh build -force $(PACKER_OPTS)

build-os-centos6:
	$(ENVS) \
	ATLAS_ARTIFACT_TYPE=openstack \
	SALT_INSTALL_OS=centos \
	./scripts/packer.sh build -only=os-centos6 $(PACKER_OPTS)

build-os-centos7:
	$(ENVS) \
	OS=centos7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=openstack \
	SALT_INSTALL_OS=centos \
	./scripts/packer.sh build -only=os-centos7 $(PACKER_OPTS)

build-os-debian9:
	$(ENVS) \
	OS=debian9 \
	OS_TYPE=debian9 \
	ATLAS_ARTIFACT_TYPE=openstack \
	SALT_INSTALL_OS=debian \
	./scripts/packer.sh build -only=os-debian9 $(PACKER_OPTS)

build-os-ubuntu12:
	$(ENVS) \
	OS=ubuntu12 \
	OS_TYPE=ubuntu12 \
	ATLAS_ARTIFACT_TYPE=openstack \
	SALT_INSTALL_OS=ubuntu \
	./scripts/packer.sh build -only=os-ubuntu12 $(PACKER_OPTS)

build-os-ubuntu14:
	$(ENVS) \
	OS=ubuntu14 \
	OS_TYPE=ubuntu14 \
	ATLAS_ARTIFACT_TYPE=openstack \
	SALT_INSTALL_OS=ubuntu \
	./scripts/packer.sh build -only=os-ubuntu14 $(PACKER_OPTS)

build-os-ubuntu16:
	$(ENVS) \
	OS=ubuntu16 \
	OS_TYPE=ubuntu16 \
	ATLAS_ARTIFACT_TYPE=openstack \
	SALT_INSTALL_OS=ubuntu \
	./scripts/packer.sh build -only=os-ubuntu16 $(PACKER_OPTS)

build-os-ubuntu18:
	$(ENVS) \
        OS=ubuntu18 \
        OS_TYPE=ubuntu18 \
        ATLAS_ARTIFACT_TYPE=openstack \
        SALT_INSTALL_OS=ubuntu \
        ./scripts/packer.sh build -only=os-ubuntu18 $(PACKER_OPTS)

build-os-sles12sp3:
	$(ENVS) \
	OS=sles12 \
	OS_TYPE=sles12 \
	ATLAS_ARTIFACT_TYPE=openstack \
	SALT_INSTALL_OS=suse \
	./scripts/packer.sh build -only=os-sles12sp3 $(PACKER_OPTS)

build-gc-centos7:
	$(ENVS) \
	GCP_STORAGE_BUNDLE=$(GCP_STORAGE_BUNDLE) \
	OS=centos7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=googlecompute \
	SALT_INSTALL_OS=centos \
	./scripts/packer.sh build -only=gc-centos7 $(PACKER_OPTS)

build-gc-sles12sp3:
	$(ENVS) \
	GCP_STORAGE_BUNDLE=$(GCP_STORAGE_BUNDLE) \
	OS=sles12 \
	OS_TYPE=sles12 \
	ATLAS_ARTIFACT_TYPE=googlecompute \
	SALT_INSTALL_OS=suse \
	./scripts/packer.sh build -only=gc-sles12sp3 $(PACKER_OPTS)

build-gc-ubuntu16:
	$(ENVS) \
	GCP_STORAGE_BUNDLE=$(GCP_STORAGE_BUNDLE) \
	OS=ubuntu16 \
	OS_TYPE=ubuntu16 \
	ATLAS_ARTIFACT_TYPE=googlecompute \
	SALT_INSTALL_OS=ubuntu \
	./scripts/packer.sh build -only=gc-ubuntu16 $(PACKER_OPTS)

build-azure-redhat6:
	$(ENVS) \
	AZURE_STORAGE_ACCOUNTS="$(AZURE_STORAGE_ACCOUNTS)" \
	OS=redhat6 \
	OS_TYPE=redhat6 \
	ATLAS_ARTIFACT_TYPE=azure-arm \
	SALT_INSTALL_OS=redhat \
	AZURE_IMAGE_PUBLISHER=RedHat \
	AZURE_IMAGE_OFFER=RHEL \
	AZURE_IMAGE_SKU=6.8 \
	SALT_REPO_FILE="salt-repo-el6.repo" \
	./scripts/packer.sh build -only=arm-rhel6 $(PACKER_OPTS)

build-azure-centos7:
	$(ENVS) \
	AZURE_STORAGE_ACCOUNTS="$(AZURE_STORAGE_ACCOUNTS)" \
	OS=centos7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=azure-arm \
	SALT_INSTALL_OS=centos \
	AZURE_IMAGE_PUBLISHER=$(AZURE_IMAGE_PUBLISHER) \
	AZURE_IMAGE_OFFER=$(AZURE_IMAGE_OFFER) \
	AZURE_IMAGE_SKU=$(AZURE_IMAGE_SKU) \
	./scripts/packer.sh build -only=arm-centos7 $(PACKER_OPTS)

build-azure-sles12sp3:
	$(ENVS) \
	AZURE_STORAGE_ACCOUNTS="$(AZURE_STORAGE_ACCOUNTS)" \
	OS=sles12 \
	OS_TYPE=sles12 \
	ATLAS_ARTIFACT_TYPE=azure-arm \
	SALT_INSTALL_OS=suse \
	AZURE_IMAGE_PUBLISHER=SUSE \
	AZURE_IMAGE_OFFER=SLES \
	AZURE_IMAGE_SKU=12-SP3 \
	./scripts/packer.sh build -only=arm-sles12sp3 $(PACKER_OPTS)

build-azure-ubuntu16:
	$(ENVS) \
	AZURE_STORAGE_ACCOUNTS="$(AZURE_STORAGE_ACCOUNTS)" \
	OS=ubuntu16 \
	OS_TYPE=ubuntu16 \
	ATLAS_ARTIFACT_TYPE=azure-arm \
	SALT_INSTALL_OS=ubuntu \
	AZURE_IMAGE_PUBLISHER=Canonical \
	AZURE_IMAGE_OFFER=UbuntuServer \
	AZURE_IMAGE_SKU=16.04-LTS \
	./scripts/packer.sh build -only=arm-ubuntu16 $(PACKER_OPTS)

copy-azure-images:
	AZURE_STORAGE_ACCOUNTS="$(AZURE_STORAGE_ACCOUNTS)" AZURE_IMAGE_NAME="$(AZURE_IMAGE_NAME)" ./scripts/azure-copy.sh
	make check-azure-images

check-azure-images:
	AZURE_STORAGE_ACCOUNTS="$(AZURE_STORAGE_ACCOUNTS)" AZURE_IMAGE_NAME="$(AZURE_IMAGE_NAME)" ./scripts/azure-image-check.sh

bundle-googlecompute:
	$(ENVS) GCP_STORAGE_BUNDLE=$(GCP_STORAGE_BUNDLE) GCP_STORAGE_BUNDLE_LOG=$(GCP_STORAGE_BUNDLE_LOG) ./scripts/bundle-gcp-image.sh

upload-openstack-image:
	S3_TARGET=$(S3_TARGET) ./scripts/openstack-upload.sh

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

docker-build-debian9:
	@ OS=debian9 OS_TYPE=debian9 TAG=debian-9 DIR=debian9 make docker-build

docker-build-ubuntu16:
	@ OS=ubuntu16 OS_TYPE=ubuntu16 TAG=ubuntu-16 DIR=ubuntu16 make docker-build

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
	cp $(shell (ls -1tr *_manifest.json | tail -1 | sed "s/_manifest//")) $(GITHUB_REPO)
	cd $(GITHUB_REPO) && git add -A && git commit -am"Upload new metadata file" && git push
	make cleanup-metadata-repo

generate-last-metadata-url-file:
	echo "METADATA_URL=https://raw.githubusercontent.com/$(GITHUB_ORG)/$(GITHUB_REPO)/master/$(shell (ls -1tr *_manifest.json | tail -1 | sed "s/_manifest//"))" > last_md
ifdef IMAGE_NAME
	echo "IMAGE_NAME=$(IMAGE_NAME)" >> last_md
endif
