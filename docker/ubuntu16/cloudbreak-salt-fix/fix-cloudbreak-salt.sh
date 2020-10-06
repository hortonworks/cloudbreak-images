#!/bin/bash

function updateIfNecessary()
{
  diff $1 $2
  if (( $? != 0 )); then
    cp $1 $2
  fi
}

updateIfNecessary /cloudbreak-salt-fix/repo/cloudera-manager.list /srv/salt/cloudera/repo/cloudera-manager.list
updateIfNecessary /cloudbreak-salt-fix/repo/init.sls /srv/salt/cloudera/repo/init.sls
updateIfNecessary /cloudbreak-salt-fix/metering/init.sls /srv/salt/metering/init.sls
updateIfNecessary /cloudbreak-salt-fix/kerberos/common.sls /srv/salt/kerberos/common.sls
