#!/usr/bin/env bash

date >> /var/log/extract.log
echo "OP: Extracting files ..." >> /var/log/extract.log

date >> /var/log/extract.log
echo "OP: Extracting salt..." >> /var/log/extract.log
tar -xvzf /opt/salt_3000.2-archive.tar.gz -C /opt >> /var/log/extract.log
date >> /var/log/extract.log

date >> /var/log/extract.log
echo "Extracting td-agent..." >> /var/log/extract.log
tar -xvzf /opt/td-agent-archive.tar.gz -C /opt >> /var/log/extract.log
date >> /var/log/extract.log

date >> /var/log/extract.log
echo "OP: Extracting python3.6 lib64..." >> /var/log/extract.log
tar -xvzf /usr/lib64/python3.6-archive.tar.gz -C /usr/lib64 >> /var/log/extract.log
date >> /var/log/extract.log

date >> /var/log/extract.log
echo "OP: Extracting python3.6 lib..." >> /var/log/extract.log
tar -xvzf /usr/lib/python3.6-archive.tar.gz -C /usr/lib >> /var/log/extract.log
date >> /var/log/extract.log

date >> /var/log/extract.log
echo "OP: Extracting python2.7(overwrite) lib64..." >> /var/log/extract.log
tar -xvzf /usr/lib64/python2.7-archive.tar.gz -C /usr/lib64 >> /var/log/extract.log
date >> /var/log/extract.log

date >> /var/log/extract.log
echo "OP: Extracting python2.7(overwrite) lib..." >> /var/log/extract.log
tar -xvzf /usr/lib/python2.7-archive.tar.gz -C /usr/lib >> /var/log/extract.log
date >> /var/log/extract.log

echo OP: Done extracting all files.




# Notes for review
# - The way EC2 launches instances, a lot of files end up being downloaded from S3? on-demand.
# 
# What shows up in scale-up timing
# - salt-minion takes 20 seconds to launch after invoking the command
# - ipa-install takes 20 seconds
# - td-agent takes 10 seconds
# - etc.
#
# Downloading single large archives seems to be faster than individual files. (python-* - 2000+ files each, salt - 3000+, td-agent - 50K+ iirc)
# Not all of these files are accessed while starting up, but a fair number are.
# Using an archive in this manner, for a single node leads to the following in terms of startup cost.
#
# extracting the files -> +5 seconds
# ipa install -> -5 to -13 seconds
# salt startup -> -15 seconds
# td-agent startup -> -5 seconds (td-agent - we likely need to purge unnecessary rubbish (man pages, unneeded plugins) in the image baking process)
# maybe some improvements in cm-agent startup


