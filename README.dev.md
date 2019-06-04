**Table of Contents**

- [Custom Images for Cloudbreak](#custom-images-for-cloudbreak)
  * [Customizing the burning process](#customizing-the-burning-process)
    + [Setting the disk size](#setting-the-disk-size)
    + [Customizing the regions](#customizing-the-regions)
  * [Customizing the Base Image](#customizing-the-base-image)
    + [Custom Base Image](#custom-base-image)
      - [AWS Example](#aws-example)
    + [Custom repositories](#custom-repositories)
    + [No internet install](#no-internet-install)
    + [Custom Script](#custom-script)
    + [Oracle JDK](#oracle-jdk)
    + [Using preinstalled JDK](#using-preinstalled-jdk)
    + [JDBC connector's JAR for MySQL or Oracle External Database](#jdbc-connectors-jar-for-mysql-or-oracle-external-database)
    + [Secure /tmp with noexec option](#secure-tmp-with-noexec-option)
  * [Packer Postprocessors](#packer-postprocessors)
  * [Saltstack installation](#saltstack-installation)
  * [Saltstack upgrade](#saltstack-upgrade)
  * [Salt-bootstrap upgrade](#salt-bootstrap-upgrade)


# Custom Images for Cloudbreak

This section covers advanced topics for building Custom Images.

## Customizing the burning process

This section presents the customizing possibilities of the image burning process.

### Setting the disk size

You can override the disk size (in GB-s, by default 25GB) of the VM used for Packer burning by modifying the `IMAGE_SIZE` parameter in the `Makefile`.

For example:
```
IMAGE_SIZE = 50
```

After saving the Makefile the modified value is applied to all subsequent image burns.

### Customizing the regions

You can set the cloud provider regions for the image to be copied over by editing the value of the following parameter in the `Makefile`. By default, burnt images are copied over to all the available regions.

 Cloud Provider | Parameter Name | Default value
 ---- | ---- | ---- |
 AWS | AWS_AMI_REGIONS | ap-northeast-1,ap-northeast-2,ap-south-1,ap-southeast-1,ap-southeast-2,ca-central-1,eu-central-1,eu-west-1,eu-west-2,eu-west-3,sa-east-1,us-east-1,us-east-2,us-west-1,us-west-2
 Azure | AZURE_STORAGE_ACCOUNTS | East Asia, East US, Central US, North Europe, South Central US, North Central US, East US 2, Japan East, Japan West, South East Asia, West US, West Europe, Brazil South, Canada East, Canada Central, Australia East, Australia South East, Central India, Korea Central, Korea South, South India, UK South, West Central US, UK West, West US 2, West India

 After saving the `Makefile` the modified values are applied to all subsequent image burns.

Note: If you experience a failure during the SSH connection step, you might need to adjust the SUBNET_ID and VPC_ID environment variable values.
E.g.:
`export SUBNET_ID=subnet-aaaaaaaaaaaaaaaa
 export VPC_ID=vpc-aaaaaaaaaaaaaaaa`

  By default the transient EC2 instance will be created in the same VPC and Subnet as the 
process building the image. 

## Customizing the Base Image

If you would like to start from a customized image, you could either:

- Set Packer to start from your [own custom image](#custom-base-image)
- Add your [custom logic](#custom-script) - either as custom script or as custom [Salt]((https://docs.saltstack.com/en/latest/)) state
- Use [Oracle JDK](#oracle-jdk) instead of OpenJDK
- Using [preinstalled JDK](#using-preinstalled-jdk)

### Custom Base Image

You have the option to start from your own pre-created source image, you have to modify the relevant section in the `builders` in the [packer.json](packer.json) file.

The following table lists the property to be modified to be able to start from a custom image:  

 Cloud Provider | Builder Name | Base Source Image Properties
 ---- | ---- | ----
 AWS | aws-amazonlinux | `source_ami: "ami-9398d3e0"` and `"region": "..."`
 AWS | aws-centos6 | `source_ami: "ami-edb9069e"` and `"region": "..."`
 AWS | aws-centos7 | `source_ami: "ami-061b1560"` and `"region": "..."`
 AWS | aws-rhel7 | `source_ami: "ami-b22961c1"` and `"region": "..."`
 Azure | arm-centos7 |  driven by input parameters:`image_publisher`, ` image_offer` and `image_sku`
 Google Cloud | gc-centos7 | `source_image: "centos-7-v20160921"`
 OpenStack | os-centos7 | `source_image: "d619e553-6a78-4b86-8b03-39b8a06df35e"`

> Note: For Azure, you can list popular images as written in [documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage#list-popular-images), but please note that only RHEL and CentOS is supported.

#### AWS Example

1. For this example, suppose you have your own RHEL 7 AMI `ami-XXXXXXXX` in region `us-east-1` in your AWS account.
2. Open the [packer.json](packer.json) file.
3. Find the section for `builders` and the section `"name": "aws-rhel7"`.
4. Modify the properties `source_ami` and `region` to match the AMI in your AWS account.
5. Save the [packer.json](packer.json) file.
6. Proceed to [AWS](README.md#aws) and run the **Build Command** for RHEL 7.

### Custom repositories

There is the possibility in Cloudbreak to use custom repositories to install Ambari and the HDP cluster, the easiest way to configure these is to place the necessary repo files (ambari.repo and hdp.repo files are necessary for installing the cluster) to your image and start the custom image creation by setting that image [as base image](#customizing-the-base-image). <br/>
For more information on how to set up a local repository please refer to the [documentation](https://docs.hortonworks.com/HDPDocuments/Ambari-2.6.1.0/bk_ambari-installation/content/setting_up_a_local_repository.html).

### No internet install

Cloudbreak supports cluster installation in a secured subnet with no internet access, to be able to do so you have to [set custom repositories](#custom-repositories), create and host a custom VDF file and update the Base URL-s of the repositories in the VDF file as well. All these resouces should be accessible by the cluster.<br/>
For more information on the VDF file refer to the [documentation](https://docs.hortonworks.com/HDPDocuments/Ambari-2.6.1.0/bk_ambari-installation/content/hdp_26_repositories.html).  

### Custom Script

Cloudbreak uses [SaltStack](https://docs.saltstack.com/en/latest/) for image provisioninig. You have an option to extend the factory scripts based on custom requirements.

> Warning: This is very advanced option. Understanding the following content requires a basic understanding of the concepts of [SaltStack](https://docs.saltstack.com/en/latest/). Please read the relevant sections of the documentation.

The provisioning steps are implemented with [Salt state files](https://docs.saltstack.com/en/latest/topics/tutorials/states_pt1.html), there is a placeholder state file called `custom`. The following section describes the steps required to extend this `custom` state with either your own script or Salt state file.

 1. Check the contents of the following directory:  `saltstack/salt/custom`, it provides extension points for implementing custom logic. The contents of the directory are the following:

| Filename | Description |
| ---- | ---- |
| `init.sls` |  Top level descriptor for state, it references other state files |
| `custom.sls` | Example for custom state file, by default it contains the example of copying and running `custom.sh` with some basic logging configured |
| `/usr/local/bin/custom.sh` | Placeholder for custom logic |

 2. You have the following options to extend this state:
 - You can place your scripts inside `custom.sh`  
 - You can copy and reference your scripts like `custom.sh` is referred from `custom.sls`.
 For each new file, a `file.managed` state is needed to copy the script to the VM and a `cmd.run` state is needed to actually run and log the script.
 - You can create and reference your state file like `custom.sls` is referred from `init.sls`. You can include any custom Salt states, if your new sls files are included in `init.sls`, they will be applied automatically  

 > Warning: Please ensure that your script runs without any errors or mandatory user inputs

### Oracle JDK

By default, OpenJDK is installed on the images. Alternatively, you can install Oracle JDK by using an optional Salt state.

To enable Oracle JDK installation you have to set the `OPTIONAL_STATES` environment variable:
```
export OPTIONAL_STATES="oracle-java"
```
Also you have to set the Oracle JDK 8 download url, which can be copied from [Oracle JDK 8 download site](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html).
> Warning: By using this JDK URL, Oracle JDK will be installed using this software and you will be agreeing to the Oracle Binary Code License agreement.

> Warning: Please use Linux x64 RPM version

To set the download url export `ORACLE_JDK8_URL_RPM` environment variable:
```
export ORACLE_JDK8_URL_RPM="https://www.oracle.com/path-to-jdk-rpm-file"
```
### Using preinstalled JDK

By default, OpenJDK is installed on the images. Alternatively, if you have an image with preinstalled JDK you can pass it's JAVA_HOME variable which would disable installation of OpenJDK.

To set your custom JAVA_HOME export `PREINSTALLED_JAVA_HOME` environment variable:
```
export PREINSTALLED_JAVA_HOME=/path/to/installed/jdk
```
> Note: If you specify preinstalled JDK but also choose Oracle JDK installation, then Oracle JDK will be installed and JAVA_HOME will be set to it

### JDBC connector's JAR for MySQL or Oracle External Database

Cloudbreak allows you to register an existing database instance to be used for a database for some supported cluster components. If you are planning to use an external database, specifically MySQL or Oracle, you must download the JDBC connector's JAR file and provide it to Cloudbreak. Typically, this is done when registering the database with Cloudbreak by providing the "Connector's JAR URL".

However, if you are burning your own custom image, you can simply place the JDBC driver in the `/opt/jdbc-drivers` directory. If you do this, you do not need to provide the "Connector's JAR URL" when registering an external database.

### Secure /tmp with noexec option

To set an additional level of security, you can enable noexec setting for /tmp partition, which does not allow execution of any binaries on /tmp folder.
By default it is turned off, to enable it you have to set the `OPTIONAL_STATES` environment variable as following:
```
export OPTIONAL_STATES="noexec-tmp"
```

## Packer Postprocessors

By default all Packer postprocessors are removed before build. This behaviour can be changed by setting the:
```
export ENABLE_POSTPROCESSORS=1
```

For example a postprocessor could be used to store image metadata into  [HashiCorp Atlas](https://www.hashicorp.com/blog/atlas-announcement/) for further processing.

If you don't know how postprocessors are working then you can safely ignore this section and please do NOT set ENABLE_POSTPROCESSORS=1 unless you know what you are doing.

## Saltstack installation

Salt will be installed in a different Python environment using virtualenv. You can specify Salt version using SALT_VERSION environment variable. 
Salt services are running with Python of the virtual environment. Hence you cannot execute salt related commands by default, you have to activate the environment.

```
source /path/to/environment/bin/activate
```

By default, the path of the virtual environment will be `/opt/salt_{SALT_VERSION}`.

Or you can use the predefined binary to activate the environment.

```
source activate_salt_env
```

If you are finished with your work with salt, you have to **deactivate the environment**:

```
deactivate
```

## Saltstack upgrade

If you want to upgrade salt installation, you have to **activate the environment** then execute the following command:

```
pip install salt=={DESIRED_SALT_VERSION} --upgrade
```

Do not forget to **deactivate** the environment:

```
deactivate
```

Be aware that the ZMQ versions should match on every instance within a cluster, so if they differ, you have to install manually ZMQ using package manager. 
To do so, package manager should contain a repository which can provide the desired ZMQ package.

After the update you should restart salt related services:

| Service type | Command |
| ---- | ---- |
| systemd | `systemctl restart salt-master`
|  | `systemctl restart salt-api`
|  | `systemctl restart salt-minion`
| amazonlinux | `service salt-master restart`
|  | `service salt-api restart`
|  | `service salt-minion restart`
| upstart | `initctl restart salt-master`
|  | `initctl restart salt-api`
|  | `initctl restart salt-minion`

## Salt-bootstrap upgrade

To upgrade salt-bootstrap, you have to download (with curl or with other preferred way) the new release package from releases of salt-bootstrap github repository and extract it into folder `/usr/sbin/salt-bootstrap`.

Then you have to restart service:

| Service type | Command |
| ---- | ---- |
| systemd | `systemctl restart salt-bootstrap`
| amazonlinux | `service salt-bootstrap restart`
| upstart | `initctl restart salt-bootstrap`
