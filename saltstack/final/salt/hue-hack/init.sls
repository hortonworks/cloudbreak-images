psycopg2-rhel8-py38-hue-hack:
  cmd.run:
    - name: rm -rf /opt/cloudera/parcels/CDH/lib/hue/build/env/lib/python3.8/site-packages/psycopg2
    - onlyif: ls -la /opt/cloudera/parcels/CDH/lib/hue/build/env/lib/python3.8/site-packages/psycopg2

