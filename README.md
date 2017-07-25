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


### GCP

Install and Setup https://cloud.google.com/sdk/docs/quickstart-mac-os-x

The following environment variables are necessary for building Google Cloud Platform images:

* GCP_ACCOUNT_FILE

```
PACKER_OPTS=--debug make build-gc-centos7
```

Without Atlas
- Delete the atlas postprocessor from `packer.json`
```
   export SALT_INSTALL_OS=centos
   export SALT_INSTALL_REPO=“https://repo.saltstack.com/yum/redhat/salt-repo-2016.11-2.el7.noarch.rpm”
   export HDP_VERSION=""
   export BASE_NAME="hdc"
   export IMAGE_NAME="hdp-1707131428"
   export GCP_ACCOUNT_FILE=/Users/<username>/.config/gcloud/legacy_credentials/<googlecloudemail>/adc.json
   export PACKER_OPTS=--debug
   
   ./scripts/packer.sh build packer_gcloud.json
```

### Running packer in debug mode

```
PACKER_OPTS=--debug make build-openstack
```

### Check the logs without debug mode
A simple file browser is launched during image creation which can be accessed on port 9999. User: `admin`, password: `secret`. 
To access the browser you need to open the port in the security groups on the cloud provider.

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
