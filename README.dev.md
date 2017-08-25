# Cloud images for Cloudbreak
Addavnced topics for building Cloudbreak Images.

### Packer postprocessors

By default all Packer postprocessors are removed before build. This behaviour can be changed by setting the: 
```
export ENABLE_POSTPROCESSORS=1
```
 
For example a postprocessor could be used to store image metadata into  [HashiCorp Atlas](https://www.hashicorp.com/blog/atlas-announcement/) for further processing. 

If you don't know how postprocessors are working then you can safely ignore this section and please do NOT set ENABLE_POSTPROCESSORS=1 unless you know what you are doing.

