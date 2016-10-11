# Cloud images for Cloudbreak
Cloud images for Cloudbreak

## Building Cloudbreak images with Packer

To change build parameters in `packer.json` or in `packer-openstack.json`  please consult with the [packer](https://www.packer.io/docs/) documentation.

### Prerequisites

Only `docker` is necessary for building cloudbreak images.

### Using without atlas

Delete the atlas postprocessor from `packer.json` or in the case of OpenStack `packer-openstack.json`.

### AWS

The following environment variables are necessary for building aws images:

* AWS_SECRET_ACCESS_KEY
* AWS_ACCESS_KEY_ID
* (ATLAS_TOKEN)

```
make build-amazon
```

### OpenStack

The following environment variables are necessary for building OpenStack images:

* OS_AUTH_URL
* OS_TENANT_NAME
* OS_USERNAME
* OS_PASSWORD
* (ATLAS_TOKEN)

```
make build-openstack
```

### Running packer in debug mode

```
PACKER_OPTS=--debug make build-openstack
```

## Building images without Packer

> *Warning:* this method is not supported or tested, it just replicates what Packer do

* tar the `shared` folder and scp into the `tmp` folder of the instance to be used for building images.

* Run the following commands:

```
# prepare scipts
sudo yum install -y rsync
sudo chown -R root:root /tmp/shared
sudo rsync -a /tmp/shared/pre/ /

# export variables
export OS_USER=...user-name...(use cloudbreak)
export PACKER_IMAGE_NAME=...image-name...
export PACKER_BUILDER_TYPE=...amazon-ebs/googlecompute/openstack....

chmod +x ./user-data-script.sh
TRACE=1 sudo -E bash ./user-data-script.sh

# cleanup
sudo rsync -a /tmp/shared/post/ /
```
create ami or image out of the instance where you executed above scripts using cloud tools.
