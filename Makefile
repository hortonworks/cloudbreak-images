BASE_NAME ?= cb
DESCRIPTION ?= "Official Cloudbreak image"
HDP_VERSION ?= ""
ATLAS_PROJECT ?= "cloudbreak"
ENABLE_POSTPROCESSORS ?= ""
CUSTOM_IMAGE_TYPE ?= "hortonworks"
IMAGE_OWNER ?= "imagebuild@hortonworks.com"
#for oracle JDK use oracle-java
OPTIONAL_STATES ?= ""
# only for oracle JDK
ORACLE_JDK8_URL_RPM ?= ""
SLES_REGISTRATION_CODE ?= ""

###############################
# DO NOT EDIT BELOW THIS LINE #
###############################

PACKAGE_VERSIONS ?= "python"
HDP_VERSION_SHORT=hdp-$(shell echo $(HDP_VERSION) | tr -d . | cut -c1-2 )
IMAGE_NAME ?= $(BASE_NAME)-$(HDP_VERSION_SHORT)-$(shell date +%y%m%d%H%M)$(IMAGE_NAME_SUFFIX)

# Use larger image size for pre-warmed images
ifeq ($(HDP_VERSION),"")
	IMAGE_SIZE = 15
else
	IMAGE_SIZE = 25
endif
# Azure has a limitation of having minimum 30 GB disk size
ifdef ARM_CLIENT_ID
	IMAGE_SIZE = 30
endif

ENVS=DESCRIPTION=$(DESCRIPTION) STACK_TYPE=$(STACK_TYPE) MPACK_URLS=$(MPACK_URLS) HDP_VERSION=$(HDP_VERSION) BASE_NAME=$(BASE_NAME) IMAGE_NAME=$(IMAGE_NAME) IMAGE_SIZE=$(IMAGE_SIZE) ENABLE_POSTPROCESSORS=$(ENABLE_POSTPROCESSORS) CUSTOM_IMAGE_TYPE=$(CUSTOM_IMAGE_TYPE) OPTIONAL_STATES=$(OPTIONAL_STATES) ORACLE_JDK8_URL_RPM=$(ORACLE_JDK8_URL_RPM) PREINSTALLED_JAVA_HOME=${PREINSTALLED_JAVA_HOME} IMAGE_OWNER=${IMAGE_OWNER} REPOSITORY_TYPE=${REPOSITORY_TYPE} PACKAGE_VERSIONS=$(PACKAGE_VERSIONS) TRACE=1

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

define AWS_AMI_REGIONS
ap-northeast-1,ap-northeast-2,ap-south-1,ap-southeast-1,ap-southeast-2,ca-central-1,eu-central-1,eu-west-1,eu-west-2,eu-west-3,sa-east-1,us-east-1,us-east-2,us-west-1,us-west-2
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
Australia South East:hwxaustralisoutheast,\
Central India:hwxcentralindia,\
Korea Central:hwxkoreacentral,\
Korea South:hwxkoreasouth,\
South India:hwxsouthindia,\
UK South:hwxsouthuk,\
West Central US:hwxwestcentralus,\
UK West:hwxwestuk,\
West US 2:hwxwestus2,\
West India:hwxwestindia,\
France Central:hwxfrancecentral
endef

GCP_STORAGE_BUNDLE ?= "sequenceiqimage"
GCP_STORAGE_BUNDLE_LOG ?= "sequenceiqimagelog"

S3_TARGET ?= "s3://public-repo-1.hortonworks.com/HDP/cloudbreak"

show-image-name:
	@echo IMAGE_NAME=$(IMAGE_NAME)

build-aws-amazonlinux:
	$(ENVS) \
	AWS_AMI_REGIONS="$(AWS_AMI_REGIONS)" \
	OS=amazonlinux \
	OS_TYPE=redhat6 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=amazon \
	SALT_REPO_FILE="salt-repo-amzn.repo" \
	./scripts/packer.sh build -only=aws-amazonlinux $(PACKER_OPTS)

build-aws-amazonlinux2:
	$(ENVS) \
	AWS_AMI_REGIONS="$(AWS_AMI_REGIONS)" \
	OS=amazonlinux2 \
	OS_TYPE=amazonlinux2 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=amazon \
	SALT_REPO_FILE="salt-repo-amazonlinux2.repo" \
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

build-aws-centos7:
	$(ENVS) \
	AWS_AMI_REGIONS="$(AWS_AMI_REGIONS)" \
	OS=centos7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=centos \
	SALT_REPO_FILE="salt-repo-el7.repo" \
	./scripts/packer.sh build -only=aws-centos7 $(PACKER_OPTS)

build-aws-rhel7:
	$(ENVS) \
	AWS_AMI_REGIONS="$(AWS_AMI_REGIONS)" \
	OS=redhat7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=redhat \
	SALT_REPO_FILE="salt-repo-el7.repo" \
	./scripts/packer.sh build -only=aws-rhel7 $(PACKER_OPTS)

build-aws-sles12sp3:
	$(ENVS) \
	AWS_AMI_REGIONS="$(AWS_AMI_REGIONS)" \
	OS=sles12 \
	OS_TYPE=sles12 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=suse \
	SALT_REPO_FILE="salt-repo-sles12.repo" \
	./scripts/packer.sh build -only=aws-sles12sp3 $(PACKER_OPTS)

build-aws-ubuntu16:
	$(ENVS) \
	AWS_AMI_REGIONS="$(AWS_AMI_REGIONS)" \
	OS=ubuntu16 \
	OS_TYPE=ubuntu16 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=ubuntu \
	SALT_REPO_FILE="salt-repo-ubuntu16.list" \
	./scripts/packer.sh build -only=aws-ubuntu16 $(PACKER_OPTS)

build-os-centos6:
	$(ENVS) \
	ATLAS_ARTIFACT_TYPE=openstack \
	SALT_INSTALL_OS=centos \
	SALT_REPO_FILE="salt-repo-el6.repo" \
	./scripts/packer.sh build -only=os-centos6 $(PACKER_OPTS)

build-os-centos7:
	$(ENVS) \
	OS=centos7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=openstack \
	SALT_INSTALL_OS=centos \
	SALT_REPO_FILE="salt-repo-el7.repo" \
	./scripts/packer.sh build -only=os-centos7 $(PACKER_OPTS)

build-os-debian9:
	$(ENVS) \
	OS=debian9 \
	OS_TYPE=debian9 \
	ATLAS_ARTIFACT_TYPE=openstack \
	SALT_INSTALL_OS=debian \
	SALT_REPO_FILE="salt-repo-debian9.list" \
	./scripts/packer.sh build -only=os-debian9 $(PACKER_OPTS)

build-os-ubuntu12:
	$(ENVS) \
	OS=ubuntu12 \
	OS_TYPE=ubuntu12 \
	ATLAS_ARTIFACT_TYPE=openstack \
	SALT_INSTALL_OS=ubuntu \
	SALT_REPO_FILE="salt-repo-ubuntu12.list" \
	./scripts/packer.sh build -only=os-ubuntu12 $(PACKER_OPTS)

build-os-ubuntu14:
	$(ENVS) \
	OS=ubuntu14 \
	OS_TYPE=ubuntu14 \
	ATLAS_ARTIFACT_TYPE=openstack \
	SALT_INSTALL_OS=ubuntu \
	SALT_REPO_FILE="salt-repo-ubuntu14.list" \
	./scripts/packer.sh build -only=os-ubuntu14 $(PACKER_OPTS)

build-os-ubuntu16:
	$(ENVS) \
	OS=ubuntu16 \
	OS_TYPE=ubuntu16 \
	ATLAS_ARTIFACT_TYPE=openstack \
	SALT_INSTALL_OS=ubuntu \
	SALT_REPO_FILE="salt-repo-ubuntu16.list" \
	./scripts/packer.sh build -only=os-ubuntu16 $(PACKER_OPTS)

build-os-sles12sp3:
	$(ENVS) \
	OS=sles12 \
	OS_TYPE=sles12 \
	ATLAS_ARTIFACT_TYPE=openstack \
	SALT_INSTALL_OS=suse \
	SALT_REPO_FILE="salt-repo-sles12.repo" \
	./scripts/packer.sh build -only=os-sles12sp3 $(PACKER_OPTS)

build-gc-centos7:
	$(ENVS) \
	GCP_STORAGE_BUNDLE=$(GCP_STORAGE_BUNDLE) \
	OS=centos7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=googlecompute \
	SALT_INSTALL_OS=centos \
	SALT_REPO_FILE="salt-repo-el7.repo" \
	./scripts/packer.sh build -only=gc-centos7 $(PACKER_OPTS)

build-gc-sles12sp3:
	$(ENVS) \
	GCP_STORAGE_BUNDLE=$(GCP_STORAGE_BUNDLE) \
	OS=sles12 \
	OS_TYPE=sles12 \
	ATLAS_ARTIFACT_TYPE=googlecompute \
	SALT_INSTALL_OS=suse \
	SALT_REPO_FILE="salt-repo-sles12.repo" \
	./scripts/packer.sh build -only=gc-sles12sp3 $(PACKER_OPTS)

build-gc-ubuntu16:
	$(ENVS) \
	GCP_STORAGE_BUNDLE=$(GCP_STORAGE_BUNDLE) \
	OS=ubuntu16 \
	OS_TYPE=ubuntu16 \
	ATLAS_ARTIFACT_TYPE=googlecompute \
	SALT_INSTALL_OS=ubuntu \
	SALT_REPO_FILE="salt-repo-ubuntu16.list" \
	./scripts/packer.sh build -only=gc-ubuntu16 $(PACKER_OPTS)

build-azure-rhel6:
	$(ENVS) \
	AZURE_STORAGE_ACCOUNTS="$(AZURE_STORAGE_ACCOUNTS)" \
	OS=redhat6 \
	OS_TYPE=redhat6 \
	ATLAS_ARTIFACT_TYPE=azure-arm \
	SALT_INSTALL_OS=redhat \
	SALT_REPO_FILE="salt-repo-el6.repo" \
	AZURE_IMAGE_PUBLISHER=RedHat \
	AZURE_IMAGE_OFFER=RHEL \
	AZURE_IMAGE_SKU=6.8 \
	./scripts/packer.sh build -only=arm-rhel6 $(PACKER_OPTS)

build-azure-centos7:
	$(ENVS) \
	AZURE_STORAGE_ACCOUNTS="$(AZURE_STORAGE_ACCOUNTS)" \
	OS=centos7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=azure-arm \
	SALT_INSTALL_OS=centos \
	SALT_REPO_FILE="salt-repo-el7.repo" \
	AZURE_IMAGE_PUBLISHER=OpenLogic \
	AZURE_IMAGE_OFFER=CentOS \
	AZURE_IMAGE_SKU=7.4 \
	./scripts/packer.sh build -only=arm-centos7 $(PACKER_OPTS)

build-azure-sles12sp3:
	$(ENVS) \
	AZURE_STORAGE_ACCOUNTS="$(AZURE_STORAGE_ACCOUNTS)" \
	OS=sles12 \
	OS_TYPE=sles12 \
	ATLAS_ARTIFACT_TYPE=azure-arm \
	SALT_INSTALL_OS=suse \
	SALT_REPO_FILE="salt-repo-sles12.repo" \
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
	SALT_REPO_FILE="salt-repo-ubuntu16.list" \
	AZURE_IMAGE_PUBLISHER=Canonical \
	AZURE_IMAGE_OFFER=UbuntuServer \
	AZURE_IMAGE_SKU=16.04-LTS \
	./scripts/packer.sh build -only=arm-ubuntu16 $(PACKER_OPTS)

copy-azure-images:
	AZURE_STORAGE_ACCOUNTS="$(AZURE_STORAGE_ACCOUNTS)" AZURE_IMAGE_NAME="$(AZURE_IMAGE_NAME)" ./scripts/azure-copy.sh

bundle-googlecompute:
	$(ENVS) GCP_STORAGE_BUNDLE=$(GCP_STORAGE_BUNDLE) GCP_STORAGE_BUNDLE_LOG=$(GCP_STORAGE_BUNDLE_LOG) ./scripts/bundle-gcp-image.sh

upload-openstack-image:
	S3_TARGET=$(S3_TARGET) ./scripts/openstack-upload.sh

docker-build:
	docker build -t registry.eng.hortonworks.com/cloudbreak/centos-7:$(shell date +%Y-%m-%d) -f docker/centos7.3/Dockerfile .

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
