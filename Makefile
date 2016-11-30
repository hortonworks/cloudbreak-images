BASE_NAME ?= "hdc"
HDP_VERSION ?= ""
ATLAS_PROJECT ?= "cloudbreak"

HDP_VERSION_SHORT=hdp-$(shell echo $(HDP_VERSION) | tr -d . | cut -c1-2 )
IMAGE_NAME=$(BASE_NAME)-$(HDP_VERSION_SHORT)-$(shell date +%y%m%d%H%M)$(IMAGE_NAME_SUFFIX)

ENVS=HDP_VERSION=$(HDP_VERSION) BASE_NAME=$(BASE_NAME) IMAGE_NAME=$(IMAGE_NAME) TRACE=1

# it testing, atlas uploads should go to mocking artifact slush
PACKER_VARS=
GIT_REV=$(shell git rev-parse --short HEAD)
GIT_BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
GIT_TAG=$(shell git describe --exact-match --tags 2>/dev/null )

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

build-amazon:
	$(ENVS) ./scripts/packer.sh build -only=amazon $(PACKER_OPTS) packer.json

build-googlecompute:
	$(ENVS) ./scripts/packer.sh build -only=googlecompute $(PACKER_OPTS) packer.json

bundle-googlecompute:
	./bundle-gcp-image.sh

build-azure:
	$(ENVS) ./scripts/packer.sh build -only=azure-arm $(PACKER_OPTS) packer.json
	$(ENVS) ./scripts/azure-copy.sh

build-openstack:
	$(ENVS) ./scripts/packer.sh build $(PACKER_OPTS) packer-openstack.json

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
