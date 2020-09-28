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

ROOT_FOLDER=/etc/autossh
mkdir -p $ROOT_FOLDER
PRIVATE_KEY=${ROOT_FOLDER}/pk.key

if grep -q "BEGIN" ${CCM_ENCIPHERED_PRIVATE_KEY_FILE}; then
    cat ${CCM_ENCIPHERED_PRIVATE_KEY_FILE} > ${PRIVATE_KEY}
else
    IV=436c6f7564657261436c6f7564657261
    cat ${CCM_ENCIPHERED_PRIVATE_KEY_FILE} | openssl enc -aes-128-cbc -d -A -a \
        -K $(xxd -pu <<< $(echo ${CCM_KEY_ID} | cut -c1-16) | cut -c1-32) \
        -iv ${IV} > ${PRIVATE_KEY}
fi

chmod 400 ${PRIVATE_KEY}

if [[ ${ROLE} == "SSH" ]]; then
    LOCAL_IP=127.0.0.1
    USER=${CCM_TUNNEL_INITIATOR_ID}_${ROLE}
else
    LOCAL_IP=0.0.0.0
    USER=${CCM_TUNNEL_INITIATOR_ID}_${ROLE}
fi

exec autossh -M 0 -o "ConnectTimeout 30" -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" \
-o UserKnownHostsFile=${CCM_PUBLIC_KEY_FILE} -N -T -R ${LOCAL_IP}:0:localhost:${CCM_TUNNEL_SERVICE_PORT} \
-i ${PRIVATE_KEY} -p ${CCM_SSH_PORT} ${USER}@${CCM_HOST} -vvv
