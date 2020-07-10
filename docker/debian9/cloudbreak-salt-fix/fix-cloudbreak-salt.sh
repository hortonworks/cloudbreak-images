#!/bin/bash

function updateIfNecessary()
{
  diff $1 $2
  if (( $? != 0 )); then
    cp $1 $2
  fi
}

updateIfNecessary /cloudbreak-salt-fix/kerberos/common.sls /srv/salt/kerberos/common.sls
