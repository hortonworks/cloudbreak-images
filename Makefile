# it testing, atlas uploads should go to mocking artifact slush
PACKER_VARS=

# this identifies images across cloud providers
CLOUDBREAK_IMAGE_VERSION=1.2.0-v8
PACKER_VARS=-var-file=vars-versions.json -var-file=vars-docker-images.json -var cloudbreak_image_version=$(CLOUDBREAK_IMAGE_VERSION)
ifdef DOCKER_VERSION
	PACKER_VARS+=-var yum_version_docker=$(DOCKER_VERSION)
endif

ifeq ($(MOCK),true)
	PACKER_OPTS +=$(PACKER_VARS) -var atlas_artifact=mock -var os_image_name=cb-centos71-amb221-2015-10-27
else
	PACKER_OPTS += $(PACKER_VARS)
endif

#deps:
	# go get github.com/bronze1man/yaml2json

build-amazon: generate-vars
	TRACE=1 ./scripts/packer.sh build -only=amazon $(PACKER_OPTS) packer.json

build-googlecompute: generate-vars
	TRACE=1 ./scripts/packer.sh build -only=googlecompute $(PACKER_OPTS) packer.json

build-azure: generate-vars
	TRACE=1 ./scripts/packer.sh build -only=azure-arm $(PACKER_OPTS) packer.json

build-openstack: generate-vars
	TRACE=1 ./scripts/packer.sh build $(PACKER_OPTS) packer-openstack.json

generate-vars: docker-build
	docker run -v $(PWD):/work -w /work --entrypoint=bash images:build -c 'make generate-vars-local'

generate-vars-local:
	cat vars-versions.yml | yaml2json | jq . > vars-versions.json
	cat vars-docker-images.yml | yaml2json | jq . > vars-docker-images.json

check-openstack:
	ATLAS=$(shell atlas -u sequenceiq -a cloudbreak -t openstack.image -f '{{ .Name }}' -m cloudbreak_image_version=$(CLOUDBREAK_IMAGE_VERSION) 2>/dev/null)
ifeq ($(ATLAS),"cloudbreak")
	  echo [WARNING] artifact already exist 
endif

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
