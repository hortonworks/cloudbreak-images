#!/bin/bash

# This is clearly a design flaw, we shall not start a new machine from a cleaned up image, because in this case we need to clean it again
echo "Deleting key.json again..."
sudo service docker stop
sudo rm -vf /etc/docker/key.json

sudo mkdir /mnt/tmp
sudo /usr/share/google/safe_format_and_mount -m "mkfs.ext4 -F" /dev/sdb /mnt/tmp
sudo gcimagebundle -d /dev/sda --skip_disk_space_check -o /mnt/tmp/ --log_file=/tmp/abc.log
curl -O https://storage.googleapis.com/pub/gsutil.tar.gz
tar xfz gsutil.tar.gz -C $HOME
export PATH=${PATH}:$HOME/gsutil
gsutil cp /mnt/tmp/*.image.tar.gz gs://sequenceiqimage/ambari21-consul-$(date +%Y-%m-%d-%H%M).image.tar.gz
