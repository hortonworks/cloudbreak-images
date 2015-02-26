#!/bin/bash

sudo mkdir /mnt/tmp
sudo /usr/share/google/safe_format_and_mount -m "mkfs.ext4 -F" /dev/sdb /mnt/tmp
sudo gcimagebundle -d /dev/sda -o /mnt/tmp/ --log_file=/tmp/abc.log
gsutil cp -a public-read /mnt/tmp/*.image.tar.gz gs://sequenceiqimage/sequenceiq-ambari17-consul-centos-$(date +%Y-%m-%d-%H%M).image.tar.gz