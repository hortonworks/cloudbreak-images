# Cloud images for Cloudbreak
Cloud images for Cloudbreak

## Building Cloudbreak images

To change build parameters in `packer.json` please consult with the [packer](https://www.packer.io/docs/) documentation.

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
