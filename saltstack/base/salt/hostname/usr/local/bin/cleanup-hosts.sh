#!/bin/bash

# Backup original file
cp /etc/hosts /etc/hosts.bak

# Remove lines marked as "Added by Google"
grep -v '# Added by Google' /etc/hosts.bak > /etc/hosts

echo "Removed Google-added lines from /etc/hosts. Backup saved as /etc/hosts.bak."