#!/bin/bash

set -x

SALT_BOOTSTRAP_VERSION=$(salt-bootstrap --version | awk '{print $2}')
KERNEL_VERSION=$(salt-call --local grains.get kernelrelease --out json | jq -r .local)
SALT_VERSION=$(salt-call --local grains.get saltversion --out json | jq -r .local)

#Determine other package versions
cat  > /tmp/package-versions.json <<EOF
{
$(for package in "$@"
do
    echo "  \"$package\" : \"$(salt-call --local pkg.version $package --out json | jq -r .local)\"",
done)
  "salt-bootstrap" : "$SALT_BOOTSTRAP_VERSION",
  "kernel" : "$KERNEL_VERSION",
  "salt" : "$SALT_VERSION"
}
EOF
chmod 744 /tmp/package-versions.json

exit 0
