#!/bin/bash

sudo mkdir -p /tmp/imagebundle
sudo gcimagebundle -d /dev/sda -o /tmp/imagebundle --fssize=16106127360 --log_file=/tmp/imagebundle/create_imagebundle.log
curl -O https://storage.googleapis.com/pub/gsutil.tar.gz
tar xfz gsutil.tar.gz -C $HOME
export PATH=${PATH}:$HOME/gsutil
gsutil cp -a public-read /tmp/imagebundle/*.image.tar.gz gs://sequenceiqimage/"$PACKER_IMAGE_NAME".tar.gz
rm -rf /tmp/imagebundle
