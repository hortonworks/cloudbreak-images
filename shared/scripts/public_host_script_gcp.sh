#!/bin/bash
echo $(curl -Ls -m 5 http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H "Metadata-Flavor: Google")