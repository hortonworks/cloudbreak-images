**Table of Contents**

- [Custom Images for Cloudbreak](#cloud-images-for-cloudbreak)
  - [What is Cloudbreak?](#what-is-cloudbreak)
  - [What are Custom Images?](#what-are-custom-images)
  - [Using this Repository](#using-this-repository)
  - [Finding the Correct Branch](#finding-the-correct-branch)
- [Building a Custom Image](#building-a-custom-image)
  - [Packer](#packer)
    - [Prerequisites](#prerequisites)
    - [AWS](#aws)
    - [Azure](#azure)
    - [OpenStack](#openstack)
    - [GCP](#gcp)
    - [Running packer in debug mode](#running-packer-in-debug-mode)
    - [Check the logs without debug mode](#check-the-logs-without-debug-mode)
    - [Advanced topics](#advanced-topics)


# Custom Images for Cloudbreak

## What is Cloudbreak?
Cloudbreak is a tool to simplify the provisioning, configuration and scaling of **Hortonworks Data Platform** clusters
on cloud provider infrastructure. Cloudbreak can be used to provision across
cloud infrastructure providers including: Amazon Web Services (AWS), Microsoft Azure and Google Cloud Platform (GCP).

Learn more about Cloudbreak here: http://hortonworks.github.io/cloudbreak-docs/

## What are Custom Images?
Cloudbreak launches clusters from an image that includes default configuration and default tooling for provisioning. These
are considered the **Standard Default** images and these images are provided with each Cloudbreak version.

From bird's-eye view, images contain the following:
- Operating system (e.g. CentOS, Amazon Linux)
- Standard configuration (disabled SE Linux, permissive iptables, best practice configs, etc.)
- Standard tooling (bootstrap scripts, bootstrap binaries)

> Important: Ambari and HDP packages are not part of the image and the desired version of Ambari and HDP packages
  are downloaded during provision time. This makes the images agnostic to the version of Ambari and HDP that can be installed by Cloudbreak.

The following **Standard Default** images and Linux versions are available for each Cloudbreak version:
- Amazon: Amazon Linux 2017
- Azure: CentOS 7.3
- GCP: CentOS 7.3
- OpenStack: CentOS 7.3

In some cases, these default images might not fit the requirements of users (e.g. they need custom OS hardening, libraries, tooling, etc) and
instead, the user would like to start their clusters from their own **custom image**. The repository includes **instructions** and **scripts** to help build those **custom images**. Once you have an images, refer to the Cloudbreak documentation
for information on how to register and use these images with Cloudbreak: http://hortonworks.github.io/cloudbreak-docs/

You have two options for building a **custom image**:

- If you are only looking to **change the OS and use a Cloudbreak base image for that OS**, use the instructions below for your
cloud provider and build the image for a different OS, or
- If you want to start from **your own base image**, follow the instructions in [Advanced topics](#advanced-topics) to
modify the `package.json` to start from your own base image.

## Using this Repository
Our recommendation is to fork this repo to to your own GitHub account or to the account of your organization and you can make changes there and create an image from there.
If you think that some of the changes you made might be useful for the Cloudbreak product as a whole, feel free to send us a pull request.

> Note: After you have have forked the repository, you are responsible to keep it up to date and fetch the latest changes from the upstream repository. 

## Finding the Correct Branch
This repository contains different branches for different Cloudbreak versions. Cloudbreak versions are defined as:
```
<major>.<minor>.<patch>[-build sequence] e.g 1.16.3 or 1.16.4-rc.7
```
If you are creating a custom image for Cloudbreak, always make sure that you are using the correct branch from `cloudbreak-images` repository.
You can find the related branch based on the <major> and <minor> version numbers of Cloudbreak (e.g if you are using 1.16.3 or 1.16.4-rc.7 version of Cloudbreak then the related branch is rc-1.16).
If you are using 2.0.1 version of Cloudbreak then the related image branch is rc-2.0.

> Note: If you do not use the appropriate branch for creating your image then there is a chance that Cloudbreak will not be able to install the cluster successfully.

# Building a Custom Image

## Packer

Images for Cloudbreak are created by [Packer](https://www.packer.io/docs/). The main entry point for creating an image is the `Makefile` which provides wrapper functionality around Packer scripts.
You can find more details about how it works in the [Packer documentation](https://www.packer.io/docs/).

Main configuration of Packer for building the Cloudbreak images is located in the `packer.json` file.

### Prerequisites

The following are requirements for the image building environment:

- [Docker](https://www.docker.com/)
- [GNU Make](https://www.gnu.org/software/make/)
- [jq](https://stedolan.github.io/jq/)

### AWS

Set the following environment variables to build AWS images:

* AWS_ACCESS_KEY_ID
* AWS_SECRET_ACCESS_KEY

Example for environment variables:
```
export AWS_ACCESS_KEY_ID=AKIAIQ**********
export AWS_SECRET_ACCESS_KEY=XHj6bjmal***********************
```

> Note: Since Packer is the underlaying technology used to build the AWS images, you can learn more 
> about the environment variables at [Packer > Amazon Reference](https://www.packer.io/docs/builders/amazon-ebs.html#configuration-reference) and the minimal set of AWS IAM or Role policies necessary at
> [Packer > Amazon EC2 Roles](https://www.packer.io/docs/builders/amazon.html#using-an-iam-task-or-instance-role)


Use the following commands to build AWS images based on the following base operating systems:

| OS | Build Command |
|---|---|
| Amazon Linux | `make build-aws-amazonlinux` |
| CentOS 6 | `make build-aws-centos6` |
| CentOS 7 | `make build-aws-centos7` |
| RHEL 7 | `make build-aws-rhel7` |

> If you want to start from **your own base image**, follow the instructions in [Advanced topics](#advanced-topics) to
modify the `package.json` to start from your own base image. Then use the commands above to build that image.

#### Permissions
The created Snapshots and AMIs will be private on AWS by default, you could use the following environment variables to change this behavior:
```
#Use this to make the created AMIs public
export MAKE_PUBLIC_AMIS=yes

#Use this to make the created Snapshot of the AMIs public
export MAKE_PUBLIC_SNAPSHOTS=yes
```

> Note: Environment variables need to be exported before the use of the `make` command.

#### Deployment Regions
The generated AMI will be deployed to multiple AWS Regions as listed in the Makefile.  So be sure to review and edit the Makefile with updates to the AWS_AMI_REGIONS and AWS_GOV_AMI_REGIONS to limit deployment.

### Azure

Set the following environment variables to build Azure images:

* ARM_CLIENT_ID
* ARM_CLIENT_SECRET
* ARM_SUBSCRIPTION_ID
* ARM_TENANT_ID
* ARM_GROUP_NAME
* ARM_STORAGE_ACCOUNT

Example for environment variables:
```
export ARM_CLIENT_ID=3234bb21-e6d0-*****-****-**********
export ARM_CLIENT_SECRET=2c8bzH******************************
export ARM_SUBSCRIPTION_ID=a9d4456e-349f-*****-****-**********
export ARM_TENANT_ID=b60c9401-2154-*****-****-**********
export ARM_GROUP_NAME=resourcegroupname
export ARM_STORAGE_ACCOUNT=storageaccountname
```

> Note: Since Packer is the underlaying technology used to build the Azure images, you can learn more 
> about the environment variables at [Packer > Azure Reference](https://www.packer.io/docs/builders/azure.html#configuration-reference).  

Use the following commands to build Azure images based on the following base operating systems:

| OS | Build Command |
|---|---|
| CentOS 7 | `make build-azure-centos7` |
| RHEL 6 | `make build-azure-rhel6` |

> If you want to start from **your own base image**, follow the instructions in [Advanced topics](#advanced-topics) to
modify the `package.json` to start from your own base image. Then use the commands above to build that image.


### GCP

Set the following environment variables to build Google Cloud Platform images:

* GCP_ACCOUNT_FILE
* GCP_CLIENT_SECRET
* GCP_PROJECT

Example for environment variables:
```
export GCP_ACCOUNT_FILE=/var/lib/jenkins/.gce/siq-haas.json
export GCP_CLIENT_SECRET=/var/lib/jenkins/.gce/client_secret.json
export GCP_PROJECT=siq-haas
```

> Note: Since Packer is the underlaying technology used to build the Google Cloud Platform images, you can learn more 
> about the environment variables at [Packer > Google Compute Reference](https://www.packer.io/docs/builders/googlecompute.html#configuration-reference).  

Use the following commands to build GCP images based on the following base operating systems:

| OS | Build Command |
|---|---|
| CentOS 7 | `make build-gc-centos7` |

> If you want to start from **your own base image**, follow the instructions in [Advanced topics](#advanced-topics) to
modify the `package.json` to start from your own base image. Then use the commands above to build that image.


### OpenStack

Set the following environment variables to build OpenStack images:

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

> Note: Since Packer is the underlaying technology used to build the OpenStack images, you can learn more 
> about the environment variables at [Packer > OpenStack Reference](https://www.packer.io/docs/builders/openstack.html#configuration-reference). 

Use the following commands to build OpenStack images based on the following base operating systems:

| OS | Build Command |
|---|---|
| CentOS 7 | `make build-os-centos7` |

> If you want to start from **your own base image**, follow the instructions in [Advanced topics](#advanced-topics) to
modify the `package.json` to start from your own base image. Then use the commands above to build that image.


### Running packer in debug mode

If you run Packer in debug mode then you can SSH into the VM during build phase and do additional debugging steps on the VM.
This is how to start a build in debug mode:

```
PACKER_OPTS=--debug make build-aws-rhel7
```
In debug mode, you need to hit enter before each step is executed by Packer. Once the VM is launched by Packer, it places a temporary SSH key in the launch directory with which you can login and do additional debug steps:

```
ssh -i ec2_aws-rhel7.pem ec2-user@<address of the machine displayed by Packer>
``` 

### Check the logs without debug mode
A simple file browser is launched during image creation which can be accessed on port 9999. 
> User: `admin`, password: `secret`.

To access the browser, you need to open port 9999 in the security group of the generated resource group manually on your cloud provider.
The generated resource group name will be displayed at the start of the build process.

E.g. on Azure:
```
    arm-centos7: Creating Azure Resource Manager (ARM) client ...
==> arm-centos7: Creating resource group ...
==> arm-centos7:  -> ResourceGroupName : 'packer-Resource-Group-qx0lx7wkg7'
==> arm-centos7:  -> Location          : 'northeurope'
==> arm-centos7:  -> Tags              :
```

## Advanced topics

You can read more about postprocessors and customizing your base image with custom scripts and logic 
[here](README.dev.md).

