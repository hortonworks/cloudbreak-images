BASE_NAME ?= "hdc"
HDP_VERSION ?= ""
ATLAS_PROJECT ?= "cloudbreak"
ENABLE_POSTPROCESSORS ?= ""

HDP_VERSION_SHORT=hdp-$(shell echo $(HDP_VERSION) | tr -d . | cut -c1-2 )
IMAGE_NAME ?= $(BASE_NAME)-$(HDP_VERSION_SHORT)-$(shell date +%y%m%d%H%M)$(IMAGE_NAME_SUFFIX)

ENVS=HDP_VERSION=$(HDP_VERSION) BASE_NAME=$(BASE_NAME) IMAGE_NAME=$(IMAGE_NAME) ENABLE_POSTPROCESSORS=$(ENABLE_POSTPROCESSORS) TRACE=1 ATLAS_ARTIFACT=$(ATLAS_PROJECT)

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

show-image-name:
	@echo IMAGE_NAME=$(IMAGE_NAME)

#deps:
	# go get github.com/bronze1man/yaml2json

build-aws-amazonlinux:
	$(ENVS) \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=amazon \
	SALT_REPO_FILE="salt-repo-2016.11-6.amzn.repo" \
	./scripts/packer.sh build -only=aws-amazonlinux $(PACKER_OPTS)

build-aws-centos6:
	$(ENVS) \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=centos \
	SALT_REPO_FILE="salt-repo-2016.11-6.el.repo" \
	$(ENVS) ./scripts/packer.sh build -only=aws-centos6 $(PACKER_OPTS)

build-aws-centos7:
	$(ENVS) \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=centos \
	SALT_REPO_FILE="salt-repo-2016.11-6.el.repo" \
	$(ENVS) ./scripts/packer.sh build -only=aws-centos7 $(PACKER_OPTS)

build-aws-rhel7:
	$(ENVS) \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=redhat \
	SALT_REPO_FILE="salt-repo-2016.11-6.el.repo" \
	$(ENVS) ./scripts/packer.sh build -only=aws-rhel7 $(PACKER_OPTS)

build-os-centos7:
	$(ENVS) \
	ATLAS_ARTIFACT_TYPE=openstack \
	ATLAS_META_OS_DISTRIBUTION_ID=CentOS \
	ATLAS_META_OS_RELEASE=7 \
    SALT_INSTALL_OS=centos \
	SALT_REPO_FILE="salt-repo-2016.11-6.el.repo" \
	$(ENVS) ./scripts/packer.sh build -only=os-centos7 $(PACKER_OPTS)

build-os-centos6:
	$(ENVS) \
	ATLAS_ARTIFACT_TYPE=openstack \
	ATLAS_META_OS_DISTRIBUTION_ID=CentOS \
	ATLAS_META_OS_RELEASE=6 \
    SALT_INSTALL_OS=centos \
	SALT_REPO_FILE="salt-repo-2016.11-6.el.repo" \
	$(ENVS) ./scripts/packer.sh build -only=os-centos6 $(PACKER_OPTS)

build-os-ubuntu14:
	$(ENVS) \
	ATLAS_ARTIFACT_TYPE=openstack \
	ATLAS_META_OS_DISTRIBUTION_ID=Ubuntu \
	ATLAS_META_OS_RELEASE=14 \
	SALT_INSTALL_OS=ubuntu \
	SALT_REPO_FILE="salt-repo-2016.11-6.ubuntu14.list" \
	$(ENVS) ./scripts/packer.sh build -only=os-ubuntu14 $(PACKER_OPTS)

build-os-ubuntu12:
	$(ENVS) \
	ATLAS_ARTIFACT_TYPE=openstack \
	ATLAS_META_OS_DISTRIBUTION_ID=Ubuntu \
	ATLAS_META_OS_RELEASE=12 \
	SALT_INSTALL_OS=ubuntu \
	SALT_REPO_FILE="salt-repo-2016.11-3.ubuntu12.list" \
	$(ENVS) ./scripts/packer.sh build -only=os-ubuntu12 $(PACKER_OPTS)

build-os-debian7:
	$(ENVS) \
	ATLAS_ARTIFACT_TYPE=openstack \
	ATLAS_META_OS_DISTRIBUTION_ID=Debian \
	ATLAS_META_OS_RELEASE=7 \
	SALT_INSTALL_OS=debian \
	SALT_REPO_FILE="salt-repo-2016.11-5.debian7.list" \
	$(ENVS) ./scripts/packer.sh build -only=os-debian7 $(PACKER_OPTS)

build-gc-centos7:
	$(ENVS) \
	ATLAS_ARTIFACT_TYPE=googlecompute \
	SALT_INSTALL_OS=centos \
	SALT_REPO_FILE="salt-repo-2016.11-6.el.repo" \
	$(ENVS) ./scripts/packer.sh build -only=gc-centos7 $(PACKER_OPTS)

build-azure-centos7:
	$(ENVS) \
	ATLAS_ARTIFACT_TYPE=azure-arm \
	SALT_INSTALL_OS=centos \
	SALT_REPO_FILE="salt-repo-2016.11-6.el.repo" \
	./scripts/packer.sh build -only=arm-centos7 $(PACKER_OPTS)
	$(ENVS) ./scripts/azure-copy.sh

bundle-googlecompute:
	$(ENVS) ./scripts/bundle-gcp-image.sh

upload-openstack-image:
	ATLAS_PROJECT=${ATLAS_PROJECT} ./scripts/openstack-s3-upload.sh

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
