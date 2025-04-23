#!/bin/bash

set -ex -o pipefail

source /etc/selinux/cdp/policy-install-utils.sh
install_policy /etc/selinux/cdp cdp-policy-installer /var/log/selinux/cdp-policy-installer.log
apply_file_contexts /etc/selinux/cdp cdp-policy-installer /var/log/selinux/cdp-policy-installer.log
