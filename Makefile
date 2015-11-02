
build-aws:
	TRACE=1 ./scripts/packer.sh build -var-file=vars.json  packer-ec2.json

build-gce:
	TRACE=1 ./scripts/packer.sh build -var-file=vars.json  packer-gce.json

build-azure:
	TRACE=1 ./scripts/packer.sh build -var-file=vars.json  packer-azure.json

build-openstack:
	TRACE=1 ./scripts/packer.sh build -var-file=vars.json  packer-openstack.json

