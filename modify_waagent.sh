#!/bin/bash

set -xe

if [ -f /etc/waagent.conf ]; then
    sudo cp /etc/waagent.conf /etc/waagent.conf.bak
    sudo sed -i 's/Provisioning.SshHostKeyPairType.*/Provisioning.SshHostKeyPairType=ecdsa/' /etc/waagent.conf
    sudo sed -i 's/Provisioning.DecodeCustomData.*/Provisioning.DecodeCustomData=y/' /etc/waagent.conf
    sudo sed -i 's/Provisioning.ExecuteCustomData.*/Provisioning.ExecuteCustomData=y/' /etc/waagent.conf
    sudo diff /etc/waagent.conf /etc/waagent.conf.bak || :
fi

