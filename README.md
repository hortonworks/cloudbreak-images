# Cloud images for Cloudbreak
Cloud images for Cloudbreak

## Building Cloudbreak images with Packer

Images for Cloudbreak are created by [Packer](https://www.packer.io/docs/). The main entry point for creating an image is the `Makefile` which provides wrapper functionality around Packer scripts. Main configuration of Packer is located `packer.json` file, you can find more details about how it works in the [Packer documentation](https://www.packer.io/docs/).

### Prerequisites

Only [Docker](https://www.docker.com/) and [GNU Make](https://www.gnu.org/software/make/) are necessary for building Cloudbreak images, since every step of image buring is encapsulated by these two Docker containers.

### Packer postprocessors

By default all Packer postprocessors are removed before build. This behaviour can be changed by setting the: 
```
export ENABLE_POSTPROCESSORS=1
```
 
For example a postprocessor could be used to store image metadata into  [HashiCorp Atlas](https://www.hashicorp.com/blog/atlas-announcement/) for further processing. 

If you don't know how postprocessors are working then you can safely ignore this section and please do NOT set ENABLE_POSTPROCESSORS=1 unless you know what you are doing.

### AWS

Following environment variables are necessary for building aws images:

* AWS_ACCESS_KEY_ID
* AWS_SECRET_ACCESS_KEY

Example for environment variables:
```
export AWS_ACCESS_KEY_ID=AKIAIQ**********
export AWS_SECRET_ACCESS_KEY=XHj6bjmal***********************
```

If you would like to build an image for AWS which is based on Amazon Linux you can execute:
```
make build-aws-amazonlinux
```

If you would like to build images based on different operating systems like CentOS 6, CentOS 7 or RHEL 7 use one of the following commands: 
```
build-aws-centos6
build-aws-centos7
build-aws-rhel7
```
### Azure

Following environment variables are necessary for building Azure images:

* ARM_CLIENT_ID
* ARM_CLIENT_SECRET
* ARM_SUBSCRIPTION_ID
* ARM_TENANT_ID
* ARM_GROUP_NAME
* ARM_STORAGE_ACCOUNT
* AZURE_IMAGE_PUBLISHER (OpenLogic|RedHat)
* AZURE_IMAGE_OFFER (CentOS|RHEL)
* AZURE_IMAGE_SKU (6.8|7.2)

Example for environment variables:
```
export ARM_CLIENT_ID=3234bb21-e6d0-*****-****-**********
export ARM_CLIENT_SECRET=2c8bzH******************************
export ARM_SUBSCRIPTION_ID=a9d4456e-349f-*****-****-**********
export ARM_TENANT_ID=b60c9401-2154-*****-****-**********
export ARM_GROUP_NAME=resourcegroupname
export ARM_STORAGE_ACCOUNT=storageaccountname
export AZURE_IMAGE_PUBLISHER=OpenLogic
export AZURE_IMAGE_OFFER=CentOS
export AZURE_IMAGE_SKU=7.2
```

If you would like to build an image for Azure which is based on CentOS 7 you can execute:
```
make build-azure-centos7
```

### OpenStack

Following environment variables are necessary for building OpenStack images:

* OS_AUTH_URL
* OS_TENANT_NAME
* OS_USERNAME
* OS_PASSWORD

Example for environment variables:
```
export OS_AUTH_URL=http://openstack.eng.hortonworks.com:5000/v2.0
export OS_USERNAME=cloudbreak
export OS_TENANT_NAME=cloudbreak
export OS_PASSWORD=**********
```

If you would like to build an image for OpenStack which is based on CentOS 7 you can execute:
```
make build-os-centos7
```


### GCP

Following environment variables are necessary for building Google Cloud Platform images:

* GCP_ACCOUNT_FILE
* GCP_CLIENT_SECRET
* GCP_PROJECT

Example for environment variables:
```
export GCP_ACCOUNT_FILE=/var/lib/jenkins/.gce/siq-haas.json
export GCP_CLIENT_SECRET=/var/lib/jenkins/.gce/client_secret.json
export GCP_PROJECT=siq-haas
```

If you would like to build an image for Google Cloud Platform which is based on CentOS 7 you can execute:
```
make build-gc-centos7
```


### Running packer in debug mode

If you run Packer in degug mode then you can ssh into the VM during build phase and do additional debuging steps on the VM:

```
PACKER_OPTS=--debug make build-aws-rhel7
```
In debug mode you need to hit enter before each step is executed by Packer. Once the VM is launched by Packer you can login and do additional debug steps:

```
ssh -i ec2_aws-rhel7.pem ec2-user@<address of the machine displayed by Packer>
``` 

### Check the logs without debug mode
A simple file browser is launched during image creation which can be accessed on port 9999. User: `admin`, password: `secret`.
To access the browser you need to open the port in the security groups on the cloud provider.

