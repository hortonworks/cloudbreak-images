# Custom Images for Cloudbreak

This section covers advanced topics for building Custom Images.

## Customizing the Base Image

If you would like to start from a customized image, you could either:

- Set Packer to start from your [own custom image](#custom_base)
- Add your [custom logic](#custom_logic) - either as custom script or as custom [Salt]((https://docs.saltstack.com/en/latest/)) state

### <a name="custom_base"></a> Custom Base Image

You have the option to start from your own pre-created source image, you have to modify the relevant section in the `builders` in the  [packer.json](packer.json) file.

The following table lists the property to be modified to be able to start from a custom image:  

 Cloud Provider | Builder Name | Source Image Property 
 ---- | ---- | ----
 AWS | aws-amazonlinux | `source_ami: "ami-9398d3e0"`
 AWS | aws-centos6 | `source_ami: "ami-edb9069e"`
 AWS | aws-centos7 | `source_ami: "ami-061b1560"`
 AWS | aws-rhel7 | `source_ami: "ami-b22961c1"`
 AWS | aws-debian7 | `source_ami: "ami-61e56916"`
 Azure | arm-centos7 |  driven by input parameters:`image_publisher`, ` image_offer` and `image_sku`
 Google Cloud | gc-centos7 | `source_image: "centos-7-v20160921"`
 OpenStack | os-centos7 | `source_image: "d619e553-6a78-4b86-8b03-39b8a06df35e"`

> Note: For Azure, you can list popular images as written in [documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage#list-popular-images), but please note that only RHEL and CentOS is supported.
 
### <a name="custom_logic"></a> Custom Script

Cloudbreak uses [SaltStack](https://docs.saltstack.com/en/latest/) for image provisioninig. You have an option to extend the factory scripts based on custom requirements.

> Warning: This is very advanced option. Understanding the following content requires a basic understanding of the concepts of [SaltStack](https://docs.saltstack.com/en/latest/). Please read the relevant sections of the documentation.

The provisioning steps are implemented with [Salt state files](https://docs.saltstack.com/en/latest/topics/tutorials/states_pt1.html), there is a placeholder state file called `custom`. The following section describes the steps required to extend this `custom` state with either your own script or Salt state file.
 
 1. Check the contents of the following directory:  `saltstack/salt/custom`, it provides extension points for implementing custom logic. The contents of the directory are the following:
 
| Filename | Description | 
| ---- | ---- |
| `init.sls` |  Top level descriptor for state, it references other state files |
| `custom.sls` | Example for custom state file, by default it contains the example of copying and running `custom.sh` with some basic logging configured |
| `/tmp/custom.sh` | Placeholder for custom logic |
 
 2. You have the following options to extend this state:
 - You can place your scripts inside `custom.sh`  
 - You can copy and reference your scripts like `custom.sh` is referred from `custom.sls`. 
 For each new file, a `file.managed` state is needed to copy the script to the VM and a `cmd.run` state is needed to actually run and log the script. 
 - You can create and reference your state file like `custom.sls` is referred from `init.sls`. You can include any custom Salt states, if your new sls files are included in `init.sls`, they will be applied automatically  
 
 > Warning: Please ensure that your script runs without any errors or mandatory user inputs


## Packer Postprocessors

By default all Packer postprocessors are removed before build. This behaviour can be changed by setting the: 
```
export ENABLE_POSTPROCESSORS=1
```
 
For example a postprocessor could be used to store image metadata into  [HashiCorp Atlas](https://www.hashicorp.com/blog/atlas-announcement/) for further processing. 

If you don't know how postprocessors are working then you can safely ignore this section and please do NOT set ENABLE_POSTPROCESSORS=1 unless you know what you are doing.

