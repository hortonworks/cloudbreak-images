#!/bin/bash -ux

SCRIPT=`basename "$0"`
ROLE=$1

. /cdp/bin/reverse-tunnel-values-${ROLE}.sh

# Setting gate time to 0 to retry on SSH failures due to connectivity issues on first try
export AUTOSSH_GATETIME=0
export AUTOSSH_LOGLEVEL=7
export AUTOSSH_LOGFILE="/var/log/autossh-${ROLE}.log"
# Set max backoff interval in case of recurring connection failures.
export AUTOSSH_POLL=30

PRIVATE_KEY=/tmp/pk.key

if grep -q "BEGIN" ${ENCIPHERED_PRIVATE_KEY}; then
    cat ${ENCIPHERED_PRIVATE_KEY} > ${PRIVATE_KEY}
else
    IV=436c6f7564657261436c6f7564657261
    cat ${ENCIPHERED_PRIVATE_KEY} | openssl enc -aes-128-cbc -d -A -a \
        -K $(xxd -pu <<< $(echo ${TUNNEL_INITIATOR_ID} | cut -c1-16) | cut -c1-32) \
        -iv ${IV} > ${PRIVATE_KEY}
fi

chmod 400 ${PRIVATE_KEY}

if [[ ${ROLE} == "SSH" ]]; then
    LOCAL_IP=127.0.0.1
    USER=${TUNNEL_INITIATOR_ID}_${ROLE}
else
    LOCAL_IP=0.0.0.0
    USER=${TUNNEL_INITIATOR_ID}_${ROLE}
fi

exec autossh -M 0 -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" \
-o UserKnownHostsFile=${PUBLIC_KEY} -N -T -R ${LOCAL_IP}:0:localhost:${HOST_PORT} \
-i ${PRIVATE_KEY} -p ${CCM_SSH_PORT} ${USER}@${HOST} -vvv
