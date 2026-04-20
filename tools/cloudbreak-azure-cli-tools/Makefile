VERSION=1.28.0
REPOSITORY=cloudbreak-tools/cloudbreak-azure-cli-tools
PLATFORMS=linux/amd64,linux/arm64

.PHONY: build build-dev release release-dev dev-all

build:
	docker build --platform $(PLATFORMS) -t $(REPOSITORY):$(VERSION) .

build-dev:
	docker build --platform $(PLATFORMS) -t $(REPOSITORY):dev .

release:
	docker tag $(REPOSITORY):$(VERSION) docker-sandbox.infra.cloudera.com/$(REPOSITORY):$(VERSION)
	docker push docker-sandbox.infra.cloudera.com/$(REPOSITORY):$(VERSION)

release-dev:
	docker tag $(REPOSITORY):dev docker-sandbox.infra.cloudera.com/$(REPOSITORY):dev
	docker push docker-sandbox.infra.cloudera.com/$(REPOSITORY):dev

dev-all:
	make build-dev
	make release-dev
