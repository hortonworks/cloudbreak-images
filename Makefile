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
	SALT_INSTALL_REPO="https://repo.saltstack.com/yum/amazon/salt-amzn-repo-2017.7-1.amzn1.noarch.rpm" \
	./scripts/packer.sh build -only=aws-amazonlinux $(PACKER_OPTS)

build-aws-centos6:
	$(ENVS) \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=centos \
	SALT_INSTALL_REPO="https://repo.saltstack.com/yum/redhat/salt-repo-2017.7-1.el6.noarch.rpm" \
	$(ENVS) ./scripts/packer.sh build -only=aws-centos6 $(PACKER_OPTS)

build-aws-centos7:
	$(ENVS) \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=centos \
	SALT_INSTALL_REPO="https://repo.saltstack.com/yum/redhat/salt-repo-2017.7-1.el7.noarch.rpm" \
	$(ENVS) ./scripts/packer.sh build -only=aws-centos7 $(PACKER_OPTS)

build-aws-rhel7:
	$(ENVS) \
	ATLAS_ARTIFACT_TYPE=amazon \
	SALT_INSTALL_OS=redhat \
	SALT_INSTALL_REPO="https://repo.saltstack.com/yum/redhat/salt-repo-2017.7-1.el7.noarch.rpm" \
	$(ENVS) ./scripts/packer.sh build -only=aws-rhel7 $(PACKER_OPTS)

build-os-centos7:
	$(ENVS) \
	ATLAS_ARTIFACT_TYPE=openstack \
	SALT_INSTALL_OS=centos \
	SALT_INSTALL_REPO="https://repo.saltstack.com/yum/redhat/salt-repo-2017.7-1.el7.noarch.rpm" \
	$(ENVS) ./scripts/packer.sh build -only=os-centos7 $(PACKER_OPTS)

build-gc-centos7:
	$(ENVS) \
	ATLAS_ARTIFACT_TYPE=googlecompute \
	SALT_INSTALL_OS=centos \
	SALT_INSTALL_REPO="https://repo.saltstack.com/yum/redhat/salt-repo-2017.7-1.el7.noarch.rpm" \
	$(ENVS) ./scripts/packer.sh build -only=gc-centos7 $(PACKER_OPTS)

build-azure-centos7:
	$(ENVS) \
	ATLAS_ARTIFACT_TYPE=azure-arm \
	SALT_INSTALL_OS=centos \
	SALT_INSTALL_REPO="https://repo.saltstack.com/yum/redhat/salt-repo-2017.7-1.el7.noarch.rpm" \
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
