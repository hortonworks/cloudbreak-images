#!/bin/bash
VERSION="1.4g"
curl https://www.harding.motd.ca/autossh/autossh-${VERSION}.tgz -s | tar xz -C .
cd autossh-${VERSION}
./configure 2>&1 >/dev/null
make 2>&1 >/dev/null
make install 2>&1 >/dev/null
