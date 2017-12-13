#!/bin/bash

## Hack to ensure nobody inside the container matches nobody on ycloud
## clusters for the sake of dist-cache permissions
useradd -u 99 nobody
usermod -u 99 nobody

groupadd -g 99 nogroup
groupmod -g 99 nogroup

groupadd -g 1006 hadoop
groupmod -g 1006 hadoop

#locations that system tests/ambari expect
mkdir -p /grid/0
chmod -R 755 /grid/
