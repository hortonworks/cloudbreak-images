# Cloud images for Cloudbreak
Cloud images for Cloudbreak

## Debug build

You can start packer build in debug mode which means:
- packer waits for ENTER after each step
- beeing able to ssh into the instance, so you can trace a build issue

```
PACKER_OPTS=--debug make build-azure
```
