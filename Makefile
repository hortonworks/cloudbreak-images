# it testing, atlas uploads should go to mocking artifact slush
PACKER_VARS=

PACKER_VARS=-var-file=vars-versions.json
ifdef DOCKER_VERSION
	PACKER_VARS+=-var yum_version_docker=$(DOCKER_VERSION)
endif

ifeq ($(MOCK),true)
	PACKER_OPTS=$(PACKER_VARS) -var atlas_artifact=mock
else
	PACKER_OPTS+=$(PACKER_VARS)
endif

deps:
ifeq (, $(shell which sigil))
	curl -L https://github.com/lalyos/sigil/releases/download/v0.4.1/sigil_0.4.1_$(shell uname)_x86_64.tgz | tar -xz -C /usr/local/bin
 endif
	# go get github.com/bronze1man/yaml2json
	
build-amazon: generate
	TRACE=1 ./scripts/packer.sh build -only=amazon $(PACKER_OPTS) packer.json

build-googlecompute: generate
	TRACE=1 ./scripts/packer.sh build -only=googlecompute $(PACKER_OPTS) packer.json

build-azure: generate
	TRACE=1 ./scripts/packer.sh build -only=azure-arm $(PACKER_OPTS) packer.json
	./scripts/azure-copy.sh

build-openstack: generate
	TRACE=1 ./scripts/packer.sh build $(PACKER_OPTS) packer-openstack.json

generate-vars: docker-build
	docker run -v $(PWD):/work -w /work --entrypoint=bash images:build -c 'make generate-vars-local'

generate-vars-local:
	cat vars-versions.yml | yaml2json | jq . > vars-versions.json

docker-build:
	docker build -t images:build - < Dockerfile.build
generate:
	SIGIL_DELIMS={{{,}}} sigil -f packer.json.tmpl ATLAS_TOKEN=$(ATLAS_TOKEN) > packer.json

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
