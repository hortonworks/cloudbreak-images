#!/bin/bash

# Backup original file
cp /etc/hosts /etc/hosts.bak

# Remove lines marked as "Added by Google" and avoid blank lines
# Readers starting in parallel (cloudera-scm-agent) must never see a truncated /etc/hosts, so write a copy and rename it.
# cp -a keeps the mode, owner and SELinux label of /etc/hosts on the copy.
TMP_HOSTS=/etc/hosts.cleanup.$$
cp -a /etc/hosts "$TMP_HOSTS"
grep -v '# Added by Google' /etc/hosts.bak | sed '/^$/d' > "$TMP_HOSTS"
if ! mv -f "$TMP_HOSTS" /etc/hosts; then
  # /etc/hosts can't be renamed over when it is a mount point
  cat "$TMP_HOSTS" > /etc/hosts
  rm -f "$TMP_HOSTS"
fi

echo "Removed Google-added lines from /etc/hosts. Backup saved as /etc/hosts.bak."