#!/bin/bash

sudo mkdir /mnt/tmp
sudo /usr/share/google/safe_format_and_mount -m "mkfs.ext4 -F" /dev/sdb /mnt/tmp
sudo gcimagebundle -d /dev/sda -o /mnt/tmp/ --fssize=30000000000 --log_file=/tmp/abc.log
gsutil cp -a public-read /mnt/tmp/*.image.tar.gz gs://sequenceiqimage/cb-centos66-amb200-$(date +%Y-%m-%d-%H%M).image.tar.gz
