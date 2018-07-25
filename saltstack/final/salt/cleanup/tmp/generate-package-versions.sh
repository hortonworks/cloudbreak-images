#!/bin/bash

#Determine salt-bootstrap version
SALT_BOOTSTRAP_VERSION=$(salt-bootstrap --version | awk '{print $2}')

#Determine other package versions
cat  > /tmp/package-versions.json <<EOF
{
$(for package in "$@"
do
    echo "  \"$package\" : \"$(salt-call --local pkg.version $package --out json | jq -r .local)\"",
done)
  "salt-bootstrap" : "$SALT_BOOTSTRAP_VERSION"
}
EOF
chmod 744 /tmp/package-versions.json

exit 0
