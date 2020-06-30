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
