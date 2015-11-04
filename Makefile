# it testing, atlas uploads should go to mocking artifact slush
PACKER_VARS=-var-file=vars-versions.json -var-file=vars-docker-images.json
ifeq ($(MOCK),true)
	PACKER_OPTS=$(PACKER_VARS) -var atlas_artifact=mock
else
	PACKER_OPTS=$(PACKER_VARS)
endif

#deps:
	# go get github.com/bronze1man/yaml2json

build-aws: generate-vars
	TRACE=1 ./scripts/packer.sh build $(PACKER_OPTS) packer-ec2.json

build-gce: generate-vars
	TRACE=1 ./scripts/packer.sh build $(PACKER_OPTS) packer-gce.json

build-azure: generate-vars
	TRACE=1 ./scripts/packer.sh build $(PACKER_OPTS) packer-azure.json

build-openstack: generate-vars
	TRACE=1 ./scripts/packer.sh build $(PACKER_OPTS) packer-openstack.json

generate-vars:
	cat vars-versions.yml | yaml2json | jq . > vars-versions.json
	cat vars-docker-images.yml | yaml2json | jq . > vars-docker-images.json
	
generate-images-var:
	sed -n 's/\(cb_[^:]*\):.*/{{ user `\1` }}/p' vars-docker-images.yml | xargs

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


