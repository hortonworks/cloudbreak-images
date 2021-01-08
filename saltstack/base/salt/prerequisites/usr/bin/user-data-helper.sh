#!/bin/bash

set -x
set

: ${CLOUD_PLATFORM:? required}
: ${START_LABEL:? required}
: ${PLATFORM_DISK_PREFIX:? required}
: ${LAZY_FORMAT_DISK_LIMIT:? required}
: ${IS_GATEWAY:? required}
: ${TMP_SSH_KEY:? required}
: ${SALT_BOOT_PASSWORD:? required}
: ${SALT_BOOT_SIGN_KEY:? required}
: ${SSH_USER:? required}

: ${XARGS_PARALLEL:=}
# : ${XARGS_PARALLEL:="-P 20"}

wait_for_authorized_keys() {
  if [[ $CLOUD_PLATFORM != "GCP" ]]; then return 0; fi
  echo "Wait for /home/${SSH_USER}/.ssh/authorized_keys to be created"
  while [[ ! -f /home/${SSH_USER}/.ssh/authorized_keys ]]; do
    echo "/home/${SSH_USER}/.ssh/authorized_keys does not exist"
    sleep 1
  done
  echo "/home/${SSH_USER}/.ssh/authorized_keys is created"
}

setup_tmp_ssh() {
  wait_for_authorized_keys
  echo "#tmpssh_start" >> /home/${SSH_USER}/.ssh/authorized_keys
  echo "$TMP_SSH_KEY" >> /home/${SSH_USER}/.ssh/authorized_keys
  echo "#tmpssh_end" >> /home/${SSH_USER}/.ssh/authorized_keys
}

format_disks() {
  lazy_format_disks
  cd /hadoopfs/fs1 && mkdir logs logs/ambari-server logs/ambari-agent logs/consul-watch logs/kerberos
}

lazy_format_disks() {
  mkdir /hadoopfs
  for (( i=1; i<=24; i++ )); do
    LABEL=$(printf "\x$(printf %x $((START_LABEL+i)))")
    DEVICE=/dev/${PLATFORM_DISK_PREFIX}${LABEL}
    if [ -e $DEVICE ]; then
      MOUNTPOINT=$(grep $DEVICE /etc/fstab | tr -s ' \t' ' ' | cut -d' ' -f 2)
      if [ -n "$MOUNTPOINT" ]; then
        umount "$MOUNTPOINT"
        sed -i "\|^$DEVICE|d" /etc/fstab
      fi
      mkfs -E lazy_itable_init=1 -O uninit_bg -F -t ext4 $DEVICE
      mkdir /hadoopfs/fs${i}
      echo UUID=$(blkid -o value $DEVICE | head -1) /hadoopfs/fs${i} ext4  defaults,noatime,nofail 0 2 >> /etc/fstab
      mount /hadoopfs/fs${i}
      chmod 777 /hadoopfs/fs${i}
    fi
  done
}

reload_sysconf() {
  sysctl -p
}

configure-salt-bootstrap() {
  mkdir -p /etc/salt-bootstrap
  chmod 700 /etc/salt-bootstrap
  cat > /etc/salt-bootstrap/security-config.yml <<EOF
username: cbadmin
password: ${SALT_BOOT_PASSWORD}
signKey: |-
 -----BEGIN PUBLIC KEY-----
 ${SALT_BOOT_SIGN_KEY}
 -----END PUBLIC KEY-----
EOF
  chmod 600 /etc/salt-bootstrap/security-config.yml
}

create_certificates_cert_tool() {
  echo n | cert-tool -d=/etc/certs -o=gateway -s localhost -s 127.0.0.1
  rm /etc/certs/client-key.pem /etc/certs/client.pem /etc/certs/ca-key.pem
  mv /etc/certs/server.pem /etc/certs/cluster.pem
  cp /etc/certs/cluster.pem /tmp/cluster.pem
  mv /etc/certs/server-key.pem /etc/certs/cluster-key.pem
}

create_certificates_certm() {
  CERT_ROOT_PATH=/etc/certs
  certm -d $CERT_ROOT_PATH ca generate -o=gateway --overwrite
  certm -d $CERT_ROOT_PATH server generate -o=gateway --host localhost --host 127.0.0.1
  mv $CERT_ROOT_PATH/server.pem $CERT_ROOT_PATH/cluster.pem
  cp $CERT_ROOT_PATH/cluster.pem /tmp/cluster.pem
  mv $CERT_ROOT_PATH/server-key.pem $CERT_ROOT_PATH/cluster-key.pem
  rm $CERT_ROOT_PATH/ca-key.pem
}

start_nginx() {
  mv /etc/nginx/sites-enabled/ssl-template /etc/nginx/sites-enabled/ssl.conf
  mkdir -p /usr/share/nginx/json/
  if [[ -d /yarn-private ]]; then
      pkill -1 -P 1 nginx
  else
      service nginx restart
  fi
  chkconfig nginx on
}

setup_tls() {
  mkdir -p /etc/certs
  echo $CB_CERT | base64 --decode > /etc/certs/cb-client.pem
  if [[ -f /sbin/certm ]]
  then
    echo "certm exists on the fs"
    create_certificates_certm
  else
    echo "cert-tool exists on the fs (backward compatibility)"
    create_certificates_cert_tool
  fi

  if [[ "$IS_CCM_V2_ENABLED" == "true" ]]; then
    echo "CCMv2 is enabled while creating an environment so ssl client verification is turned off and localhost:9443 used"
    sed -i -E "s/ssl_verify_client(\s)+on;/ssl_verify_client off;/" /etc/nginx/sites-enabled/ssl-template
    sed -i -E "s/listen(\s)+9443;/listen       localhost:9443;/" /etc/nginx/sites-enabled/ssl-template
  fi
}

setup_ccm() {
  : ${CCM_HOST:? required}
  : ${CCM_SSH_PORT:? required}
  : ${CCM_PUBLIC_KEY:? required}
  : ${CCM_KEY_ID:? required}
  : ${CCM_TUNNEL_INITIATOR_ID:="$INSTANCE_ID"}
  : ${CCM_ENCIPHERED_PRIVATE_KEY:? required}

  mkdir -p /etc/ccm

  CCM_PUBLIC_KEY_FILE=/etc/ccm/ccm.pub
  echo "$CCM_PUBLIC_KEY" | base64 --decode > "$CCM_PUBLIC_KEY_FILE"
  chmod 400 "$CCM_PUBLIC_KEY_FILE"

  CCM_ENCIPHERED_PRIVATE_KEY_FILE=/etc/ccm/initiator.enc
  echo "$CCM_ENCIPHERED_PRIVATE_KEY" | base64 --decode > "$CCM_ENCIPHERED_PRIVATE_KEY_FILE"
  chmod 400 "$CCM_ENCIPHERED_PRIVATE_KEY_FILE"

  if [[ -n "$CCM_GATEWAY_PORT" ]]; then
    update_reverse_tunnel_values GATEWAY "$CCM_GATEWAY_PORT"
  fi
  if [[ -n "$CCM_KNOX_PORT" ]]; then
    update_reverse_tunnel_values KNOX "$CCM_KNOX_PORT"
  fi
  if [[ "$IS_PROXY_ENABLED" == "true" ]]; then
    setup_ssh_proxy
  fi
}

setup_ccmv2() {
  : ${CCM_V2_INVERTING_PROXY_CERTIFICATE:? required}
  : ${CCM_V2_INVERTING_PROXY_HOST:? required}
  : ${CCM_V2_AGENT_CERTIFICATE:? required}
  : ${CCM_V2_AGENT_ENCIPHERED_KEY:? required}
  : ${CCM_V2_AGENT_KEY_ID:? required}
  : ${CCM_V2_AGENT_CRN:? required}
  : ${CCM_V2_AGENT_BACKEND_ID_PREFIX:? required}

  BACKEND_ID="${CCM_V2_AGENT_BACKEND_ID_PREFIX}${INSTANCE_ID}"
  BACKEND_HOST="localhost"
  BACKEND_PORT="9443"

  mkdir -p /etc/ccmv2

  IV=436c6f7564657261436c6f7564657261
  AGENT_KEY_PATH=/etc/ccmv2/ccmv2-key.enc
  echo ${CCM_V2_AGENT_ENCIPHERED_KEY} | openssl enc -aes-128-cbc -d -A -a -K ${CCM_V2_AGENT_KEY_ID} -iv ${IV} > ${AGENT_KEY_PATH}
  chmod 400 "$AGENT_KEY_PATH"

  AGENT_CERT_PATH=/etc/ccmv2/ccmv2-cert.enc
  echo "$CCM_V2_AGENT_CERTIFICATE" | base64 --decode > "$AGENT_CERT_PATH"
  chmod 400 "$AGENT_CERT_PATH"

  TRUSTED_BACKEND_CERT_PATH="/etc/certs/cluster.pem"

  TRUSTED_PROXY_CERT_PATH=/etc/ccmv2/ccmv2-proxy-cert.enc
  echo "$CCM_V2_INVERTING_PROXY_CERTIFICATE" | base64 --decode > "$TRUSTED_PROXY_CERT_PATH"
  chmod 400 "$TRUSTED_PROXY_CERT_PATH"

  INVERTING_PROXY_URL="$CCM_V2_INVERTING_PROXY_HOST"

  update-inverting-proxy-agent-values.sh "$BACKEND_ID" "$BACKEND_HOST" "$BACKEND_PORT" "$AGENT_KEY_PATH" "$AGENT_CERT_PATH" "$TRUSTED_BACKEND_CERT_PATH" "$TRUSTED_PROXY_CERT_PATH" "$INVERTING_PROXY_URL"
}

setup_ssh_proxy() {
  : ${PROXY_HOST:? required}
  : ${PROXY_PORT:? required}

  mkdir -p /root/.ssh
  PROXY_COMMAND="ProxyCommand /usr/bin/corkscrew ${PROXY_HOST} ${PROXY_PORT} %h %p"
  if [[ ! -z ${PROXY_USER} ]]; then
    echo "${PROXY_USER}:${PROXY_PASSWORD}" > /root/.ssh/proxy_auth
    chmod 600 /root/.ssh/proxy_auth
    PROXY_COMMAND+=" /root/.ssh/proxy_auth"
  fi
  echo ${PROXY_COMMAND} >> /root/.ssh/config
}

update_reverse_tunnel_values() {
  CCM_HOST="$CCM_HOST" \
  CCM_SSH_PORT="$CCM_SSH_PORT" \
  CCM_PUBLIC_KEY_FILE="$CCM_PUBLIC_KEY_FILE" \
  CCM_TUNNEL_INITIATOR_ID="$CCM_TUNNEL_INITIATOR_ID" \
  CCM_ENCIPHERED_PRIVATE_KEY_FILE="$CCM_ENCIPHERED_PRIVATE_KEY_FILE" \
  /cdp/bin/update-reverse-tunnel-values.sh "$1" "$2"
}

create_saltapi_certificates() {
  source activate_salt_env
  salt-call --local tls.create_self_signed_cert CN='saltapi' days=3650 replace=Tru
  deactivate
  rm -f /etc/salt/minion_id
}

main() {
  configure-salt-bootstrap
  reload_sysconf
  if [[ "$1" == "::" ]]; then
    shift
    eval "$@"
  elif [ ! -f "/var/cb-init-executed" ]; then
    [[ $CLOUD_PLATFORM == "OPENSTACK" ]] && format_disks
    if [[ "$IS_GATEWAY" == "true" ]]; then
      setup_tmp_ssh
      if [[ -n "$CB_CERT" ]]; then
        setup_tls
        start_nginx
      fi
      create_saltapi_certificates
    fi

    INSTANCE_ID=
    if [[ "$CLOUD_PLATFORM" == "AWS" ]]; then
      INSTANCE_ID="`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`"
    elif [[ "$CLOUD_PLATFORM" == "AZURE" ]]; then
      INSTANCE_ID="`wget -q -O - --header="Metadata: true" 'http://169.254.169.254/metadata/instance/compute/name?api-version=2017-08-01&format=text'`"
    elif [[ "$CLOUD_PLATFORM" == "GCP" ]]; then
      INSTANCE_ID="`wget -q -O - --header="Metadata-Flavor: Google" 'http://metadata.google.internal/computeMetadata/v1/instance/name'`"
    fi

    if [[ "$IS_CCM_ENABLED" == "true" ]]; then
      setup_ccm
    elif [[ "$IS_CCM_V2_ENABLED" == "true" ]]; then
      setup_ccmv2
    fi

    echo $(date +%Y-%m-%d:%H:%M:%S) >> /var/cb-init-executed
  fi
  [ -e /usr/bin/ssh-aliases ] && /usr/bin/ssh-aliases create
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
