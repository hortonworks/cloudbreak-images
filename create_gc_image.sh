#!/bin/bash

sudo mkdir /mnt/tmp
sudo /usr/share/google/safe_format_and_mount -m "mkfs.ext4 -F" /dev/sdb /mnt/tmp
sudo gcimagebundle -d /dev/sda --skip_disk_space_check -o /mnt/tmp/ --log_file=/tmp/abc.log
curl -O https://storage.googleapis.com/pub/gsutil.tar.gz
tar xfz gsutil.tar.gz -C $HOME
export PATH=${PATH}:$HOME/gsutil
gsutil cp /mnt/tmp/*.image.tar.gz gs://sequenceiqimage/ambari17-consul-$(date +%Y-%m-%d-%H%M).image.tar.gz
