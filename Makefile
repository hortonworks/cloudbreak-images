BASE_NAME ?= "cloudbreak"
DESCRIPTION ?= "Official Cloudbreak image"
HDP_VERSION ?= ""
ATLAS_PROJECT ?= "cloudbreak"
ENABLE_POSTPROCESSORS ?= ""
CUSTOM_IMAGE_TYPE ?= "hortonworks"
#for oracle JDK use oracle-java
OPTIONAL_STATES ?= ""
# only for oracle JDK
ORACLE_JDK8_URL_RPM ?= "http://download.oracle.com/otn-pub/java/jdk/8u151-b12/e758a0de34e24606bca991d704f6dcbf/jdk-8u151-linux-x64.rpm"

HDP_VERSION_SHORT=hdp-$(shell echo $(HDP_VERSION) | tr -d . | cut -c1-2 )
IMAGE_NAME ?= $(BASE_NAME)-$(HDP_VERSION_SHORT)-$(shell date +%y%m%d%H%M)$(IMAGE_NAME_SUFFIX)

ENVS=DESCRIPTION=$(DESCRIPTION) HDP_VERSION=$(HDP_VERSION) BASE_NAME=$(BASE_NAME) IMAGE_NAME=$(IMAGE_NAME) ENABLE_POSTPROCESSORS=$(ENABLE_POSTPROCESSORS) CUSTOM_IMAGE_TYPE=$(CUSTOM_IMAGE_TYPE) OPTIONAL_STATES=$(OPTIONAL_STATES) ORACLE_JDK8_URL_RPM=$(ORACLE_JDK8_URL_RPM) TRACE=1

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
ap-southeast-1,ap-southeast-2,eu-central-1,ap-northeast-1,ap-northeast-2,us-east-1,sa-east-1,us-west-1,us-west-2
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
Southeast Asia:sequenceiqsoutheastasia2,\
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
West India:hwxwestindia
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
	SALT_INSTALL_REPO="https://repo.saltstack.com/yum/amazon/salt-amzn-repo-2017.7-1.amzn1.noarch.rpm" \
	./scripts/packer.sh build -only=aws-amazonlinux $(PACKER_OPTS)

build-aws-centos6:
	$(ENVS) \
	AWS_AMI_REGIONS="$(AWS_AMI_REGIONS)" \
	OS=centos6 \
	OS_TYPE=redhat6 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=centos \
	SALT_INSTALL_REPO="https://repo.saltstack.com/yum/redhat/salt-repo-2017.7-1.el6.noarch.rpm" \
	./scripts/packer.sh build -only=aws-centos6 $(PACKER_OPTS)

build-aws-centos7:
	$(ENVS) \
	AWS_AMI_REGIONS="$(AWS_AMI_REGIONS)" \
	OS=centos7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=centos \
	SALT_INSTALL_REPO="https://repo.saltstack.com/yum/redhat/salt-repo-2017.7-1.el7.noarch.rpm" \
	./scripts/packer.sh build -only=aws-centos7 $(PACKER_OPTS)

build-aws-rhel7:
	$(ENVS) \
	AWS_AMI_REGIONS="$(AWS_AMI_REGIONS)" \
	OS=redhat7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=redhat \
	SALT_INSTALL_REPO="https://repo.saltstack.com/yum/redhat/salt-repo-2017.7-1.el7.noarch.rpm" \
	./scripts/packer.sh build -only=aws-rhel7 $(PACKER_OPTS)

build-os-centos7:
	$(ENVS) \
	OS=centos7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=openstack \
	SALT_INSTALL_OS=centos \
	SALT_INSTALL_REPO="https://repo.saltstack.com/yum/redhat/salt-repo-2017.7-1.el7.noarch.rpm" \
	./scripts/packer.sh build -only=os-centos7 $(PACKER_OPTS)

build-gc-centos7:
	$(ENVS) \
	GCP_STORAGE_BUNDLE=$(GCP_STORAGE_BUNDLE) \
	OS=centos7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=googlecompute \
	SALT_INSTALL_OS=centos \
	SALT_INSTALL_REPO="https://repo.saltstack.com/yum/redhat/salt-repo-2017.7-1.el7.noarch.rpm" \
	./scripts/packer.sh build -only=gc-centos7 $(PACKER_OPTS)

build-azure-centos7:
	$(ENVS) \
	AZURE_STORAGE_ACCOUNTS="$(AZURE_STORAGE_ACCOUNTS)" \
	OS=centos7 \
	OS_TYPE=redhat7 \
	ATLAS_ARTIFACT_TYPE=azure-arm \
	SALT_INSTALL_OS=centos \
	SALT_INSTALL_REPO="https://repo.saltstack.com/yum/redhat/salt-repo-2017.7-1.el7.noarch.rpm" \
	./scripts/packer.sh build -only=arm-centos7 $(PACKER_OPTS)

copy-azure-images:
	AZURE_STORAGE_ACCOUNTS="$(AZURE_STORAGE_ACCOUNTS)" ./scripts/azure-copy.sh

bundle-googlecompute:
	$(ENVS) GCP_STORAGE_BUNDLE=$(GCP_STORAGE_BUNDLE) GCP_STORAGE_BUNDLE_LOG=$(GCP_STORAGE_BUNDLE_LOG) ./scripts/bundle-gcp-image.sh

upload-openstack-image:
	ATLAS_PROJECT=${ATLAS_PROJECT} S3_TARGET=$(S3_TARGET) ./scripts/openstack-s3-upload.sh

docker-build:
	docker build -t images:build - < Dockerfile.build

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
	cp $(shell (ls -1 *_manifest.json | tail -1 | sed "s/_manifest//")) $(GITHUB_REPO)
	cd $(GITHUB_REPO) && git add -A && git commit -am"Upload new metadata file" && git push
	make cleanup-metadata-repo

generate-last-metadata-url-file:
	echo "METADATA_URL=https://raw.githubusercontent.com/$(GITHUB_ORG)/$(GITHUB_REPO)/master/$(shell (ls -1 *_manifest.json | tail -1 | sed "s/_manifest//"))" > last_md