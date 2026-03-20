#!/bin/bash

echo "Currently installed kernels:"
rpm -qa | grep kernel-core

current=$(uname -r | sed 's/\.aarch64//')
echo "Currently used kernel: $current"

for k in $(rpm -qa | grep kernel-core | sed 's/kernel-core-//;s/\.aarch64//'); do
    if [[ "$k" != "$current" ]]; then
        echo "Removing kernel-core-$k..."
        sudo dnf -y remove kernel-core-$k.aarch64
    fi
done