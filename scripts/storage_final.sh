#!/bin/bash
if [ "${OS}" == "centos7" ] && [ "${CLOUD_PROVIDER}" == "Azure" ] ; then
    xfs_growfs -d /dev/sda2

    #Print the current disk sizes
    lsblk
    #Print partition sizes
    df -h
fi