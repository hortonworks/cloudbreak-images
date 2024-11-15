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
