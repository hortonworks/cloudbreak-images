# Cloud images for Cloudbreak

Cloudbreak, as part of the Hortonworks Data Platform, makes it easy to provision, configure and elastically grow HDP clusters on cloud infrastructure. Cloudbreak can be used to provision Hadoop across cloud infrastructure providers including Amazon Web Services, Microsoft Azure, Google Cloud Platform and OpenStack.

Cloudbreak can launch clusters from images which includes default configuration and default  tooling for provision, but it does not necessarily includes Ambari / HDP package. Hortonworks makes a  set of such images publicly available for every released Cloudbreak version, but in some cases these publicly available images might not fit to the expectations of customers, because they would like to start the cluster from their own image.

## Default image content
From bird's perspective images contain the followings:
- Operating system (Red Hat derivative e.g CentOS, Amazon Linux, RHEL)
- Standard configuration (disabled SE Linux, permissive iptables, best practice configs, etc.)
- Standard tooling (bootstrap scripts, bootstrap binaries)

Images do not limit the version of Ambari and HDP that can be installed by Cloudbreak. Ambari and HDP packages are not part of the image and the desired version of Ambari/HDP packages are downloaded during provision time. 

## Supported Operating Systems
Cloudbreak supports Red Hat Linux based operating systems, by default the following images are publicly available:
- Amazon: Amazon Linux 2017
- Azure: CentOS 7.3
- GCP: CentOS 7.3
- OpenStack: CentOS 7.3

It is also possible to create CentOS 6.x, CentOS 7.x, RHEL 6.x, RHEL 7.x based images for every platform. 

## Access to image repository
The recommended way is to fork this repo to to your own github account or to the account of your organisation and you can make changes there and create an image for there.
If you think that some of the changes you made might be useful for Cloudbreak product then you can raise a JIRA and send us a pull request.

Note: After you have have forked the repository you are responsible to keep it up to date and fetch the latest changes from upstream. 

## Finding the right branch
Cloudbreak-images repository contains different branches for different Cloudbreak versions. Cloudbreak version is defined as:
```
<major>.<minor>.<patch>[-build sequence] e.g 1.16.3 or 1.16.4-rc.7
```

If you are creating a custom image for Cloudbreak,  always make sure that you are using the correct branch from cloudbreak-images git repository.  You can find the related branch based on the <major> and <minor> version numbers of Cloudbreak, e.g if you are using 1.16.3 or 1.16.4-rc.7 version of Cloudbreak then the related branch is rc-1.16. If you are using 2.0.1 version of Cloudbreak then the related image branch is rc-2.0.

Note: If you are not using the appropriate branch for creating your image then most probably Cloudbreak will not be able to install the cluster successfully.

## Building Cloudbreak images with Packer

Images for Cloudbreak are created by [Packer](https://www.packer.io/docs/). The main entry point for creating an image is the `Makefile` which provides wrapper functionality around Packer scripts. Main configuration of Packer is located `packer.json` file, you can find more details about how it works in the [Packer documentation](https://www.packer.io/docs/).

### Prerequisites

Only [Docker](https://www.docker.com/) and [GNU Make](https://www.gnu.org/software/make/) are necessary for building Cloudbreak images, since every step of image buring is encapsulated by these two Docker containers.

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

