CBD_VERSION=1.4.0-rc.16
CBD_VERSION_UNDERSCORE=$(shell echo $(CBD_VERSION) | tr -d .)
NEXT_ATLAS_VERSION=$(shell atlas -s sequenceiq/cbd/amazon-linux.image -f '{{add .Version  1}}' -l)

ENVS=CBD_VERSION=$(CBD_VERSION) CBD_VERSION_UNDERSCORE=$(CBD_VERSION_UNDERSCORE) TRACE=1
# it testing, atlas uploads should go to mocking artifact slush
PACKER_VARS=

PACKER_VARS=-var-file=vars-versions.json
ifdef DOCKER_VERSION
	PACKER_VARS+=-var yum_version_docker=$(DOCKER_VERSION)
endif

ifeq ($(MOCK),true)
	PACKER_OPTS+=$(PACKER_VARS) -var atlas_artifact=mock
else
	PACKER_OPTS+=$(PACKER_VARS)
endif

deps:
	curl -L https://github.com/lalyos/atlas/releases/download/v0.0.5/atlas_0.0.5_$(shell uname)_x86_64.tgz | tar -xz -C /usr/local/bin/
	# go get github.com/bronze1man/yaml2json

build-amazon: generate-vars
	$(ENVS) ./scripts/packer.sh build -only=amazon $(PACKER_OPTS) packer.json

build-amazon-linux: generate-vars
	$(ENVS) ./scripts/packer.sh build -only=amazon-linux $(PACKER_OPTS) packer-amazon-linux.json

build-googlecompute: generate-vars
	$(ENVS) ./scripts/packer.sh build -only=googlecompute $(PACKER_OPTS) packer.json

build-azure: generate-vars
	$(ENVS) ./scripts/packer.sh build -only=azure-arm $(PACKER_OPTS) packer.json

build-openstack: generate-vars
	$(ENVS) ./scripts/packer.sh build $(PACKER_OPTS) packer-openstack.json

generate-vars: docker-build
	docker run -v $(PWD):/work -w /work --entrypoint=bash images:build -c 'make generate-vars-local'

generate-vars-local:
	cat vars-versions.yml | yaml2json | jq . > vars-versions.json

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
