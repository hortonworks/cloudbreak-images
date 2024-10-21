### A COLLECTION OF HACKS AND TEMPORARY SOLUTIONS. Rules:
### 
### - Add stuff here only if you either need a small, quick fix for something or it's something temporary. 
### - Retrict the area of effect of the hack as much as possible.
### - Do not leave temp files, etc. behind.
### - ALWAYS include a ticket ID for later reference.
###

# This could be removed (proably along with the whole Psycopg2 stuff!) once CDPD-71074 gets delivered to 7.2.18 and above
{% if salt['environ.get']('CLOUD_PROVIDER') == 'AWS_GOV' %}
psycopg2-rhel8-py38-hue-hack:
  cmd.run:
    - name: rm -rf /opt/cloudera/parcels/CDH/lib/hue/build/env/lib/python3.8/site-packages/psycopg2*
    - onlyif: ls -la /opt/cloudera/parcels/CDH/lib/hue/build/env/lib/python3.8/site-packages/psycopg2
{% endif %}

# Not sure when we'll be able to remove this hack, but right now we need a quick solution because the existence of this file causes
# problems on GCP. Read the comments of CB-27565 for more details.
{% if salt['environ.get']('OS') == 'redhat8' and salt['environ.get']('RHEL_VERSION') == '8.10' and salt['environ.get']('CLOUD_PROVIDER') == 'GCP' %}
remove-rhel810-gcp-dns-override:
  cmd.run:
    - name: rm -f /etc/NetworkManager/dispatcher.d/google_hostname.sh
{% endif %}
