#!/bin/bash

set -ex
set

if [[ "$SECRET_ENCRYPTION_ENABLED" == "true" ]]; then
  source /usr/bin/cdp-retrieve-userdata-secrets.sh &> /var/log/cdp-retrieve-userdata-secrets.log
fi

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
: ${PROXY_PROTOCOL:=http}

{% if pillar['CUSTOM_IMAGE_TYPE'] == 'freeipa' %}
export IS_FREEIPA=true
{% else %}
export IS_FREEIPA=false
{% endif %}
OS={{ pillar['OS'] }}

source /usr/bin/ccmv2-helper.sh

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
  cd /hadoopfs/fs1 && mkdir logs logs/ambari-server logs/ambari-agent logs/kerberos
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

create_luks_volume() {
  ENCRYPTION_KEY_FILE="/etc/cdp-luks/passphrase_encryption_key"
  install -m 600 /dev/null "$ENCRYPTION_KEY_FILE"
  echo "$SECRET_ENCRYPTION_KEY_SOURCE" > "$ENCRYPTION_KEY_FILE"

  echo "LUKS volume creation started."
  /etc/cdp-luks/bin/create-luks-volume.sh 2>&1 | tee /var/log/cdp-luks/create-luks-volume.log
  result=${PIPESTATUS[0]}
  echo "LUKS volume creation finished with: $result"
  return $result
}

populate_luks_volume() {
  echo "LUKS volume population with secrets started."
  /etc/cdp-luks/bin/populate-luks-volume.sh 2>&1 | tee /var/log/cdp-luks/populate-luks-volume.log
  result=${PIPESTATUS[0]}
  echo "LUKS volume population with secrets finished with: $result"
  return $result
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
  # TODO Remove once CB-29572 is done
  restorecon -R -v -i /etc/salt-bootstrap
}

create_certificates_certm() {
  CERT_ROOT_PATH=/etc/certs
  certm -d $CERT_ROOT_PATH ca generate -o=gateway --overwrite
  certm -d $CERT_ROOT_PATH server generate -o=gateway --host localhost --host 127.0.0.1
  mv $CERT_ROOT_PATH/server.pem $CERT_ROOT_PATH/cluster.pem
  cp $CERT_ROOT_PATH/cluster.pem /tmp/cluster.pem
  mv $CERT_ROOT_PATH/server-key.pem $CERT_ROOT_PATH/cluster-key.pem
  rm $CERT_ROOT_PATH/ca-key.pem
  cp $CERT_ROOT_PATH/cluster.pem /etc/jumpgate/cluster.pem
  chmod 600 /etc/jumpgate/cluster.pem
  chown jumpgate:jumpgate /etc/jumpgate/cluster.pem
}

create_cert_for_saltboot_tls() {
  local CERT_ROOT_PATH=/etc/salt-bootstrap/certs
  certm -d $CERT_ROOT_PATH ca generate -o=saltboot --overwrite
  certm -d $CERT_ROOT_PATH server generate -o=saltboot --cert $CERT_ROOT_PATH/saltboot.pem --key $CERT_ROOT_PATH/saltboot-key.pem --overwrite
  rm $CERT_ROOT_PATH/ca-key.pem
  # TODO Remove once CB-29572 is done
  restorecon -R -v -i $CERT_ROOT_PATH
}

start_nginx() {
  mv /etc/nginx/sites-enabled/ssl-template /etc/nginx/sites-enabled/ssl.conf
  mkdir -p /usr/share/nginx/json/
  if [[ -d /yarn-private ]]; then
      pkill -1 -P 1 nginx || true
  else
      service nginx restart
  fi
  chkconfig nginx on
}

setup_tls() {
  mkdir -p /etc/certs
  echo $CB_CERT | base64 --decode > /etc/certs/cb-client.pem
  create_certificates_certm

  if [[ "$IS_CCM_V2_ENABLED" == "true" ]]; then
    if [[ "$IS_CCM_V2_JUMPGATE_ENABLED" == "true" ]]; then
      echo "CCMv2 Jumpgate is enabled while creating an environment so ssl client verification is turned off"
      sed -i -E "s/ssl_verify_client(\s)+on;/ssl_verify_client off;/" /etc/nginx/sites-enabled/ssl-template
    else
      echo "CCMv2 is enabled while creating an environment so ssl client verification is turned off and 127.0.0.1:9443 used"
      sed -i -E "s/ssl_verify_client(\s)+on;/ssl_verify_client off;/" /etc/nginx/sites-enabled/ssl-template
      sed -i -E "s/listen(\s)+9443;/listen       127.0.0.1:9443;/" /etc/nginx/sites-enabled/ssl-template
    fi
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

setup_proxy() {
    if [[ -z ${PROXY_USER} ]]; then
      PROXY_URL="$PROXY_PROTOCOL://$PROXY_HOST:$PROXY_PORT"
    else
      PROXY_URL="$PROXY_PROTOCOL://${PROXY_USER}:${PROXY_PASSWORD}@$PROXY_HOST:$PROXY_PORT"
    fi
    PROXY_ENV_FILE=/etc/cdp/proxy.env
    mkdir -p /etc/cdp
    echo https_proxy=$PROXY_URL > $PROXY_ENV_FILE
    if  [[ ! -z ${PROXY_NO_PROXY_HOSTS} ]]; then
      echo no_proxy=${PROXY_NO_PROXY_HOSTS} >> $PROXY_ENV_FILE
    fi
    chmod 640 $PROXY_ENV_FILE
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

resize_partitions() {
  if [ $CLOUD_PLATFORM == "AZURE" ] && ([ $OS == "redhat7" ] || [ $OS == "redhat8" ]); then
    if [ $OS == "redhat7" ]; then
      # Relocating backup data structures to the end of the disk
      printf "x\ne\nw\nY\n" | gdisk /dev/sda
      # Resize /dev/sda4 to the end of the disk
      parted -s -a opt /dev/sda "resizepart 4 100%"
      # Resize physical volume
      pvresize /dev/sda4
      # Extend logical volumes to satisfy CM free space checks
      lvextend -L35G -r /dev/mapper/rootvg-optlv
      lvextend -L12G -r /dev/mapper/rootvg-varlv
      lvextend -L12G -r /dev/mapper/rootvg-tmplv
    elif [ $OS == "redhat8" ]; then
      PV_NAME=$(pvs --noheadings --rows | head -1 | tr -d '[:space:]')
      DISK=${PV_NAME//[0-9]/}
      PARTITION=${PV_NAME//[^0-9]/}
      # Relocating backup data structures to the end of the disk
      printf "x\ne\nw\nY\n" | gdisk $DISK
      # Resize partition to the end of the disk
      parted -s -a opt $DISK "resizepart $PARTITION 100%"
      # Resize physical volume
      pvresize $PV_NAME
      # Extend logical volumes to satisfy CM free space checks and allocate remaining free space
      lvextend -L50G -r /dev/mapper/rootvg-varlv
      lvextend -L12G -r /dev/mapper/rootvg-tmplv
      lvextend -L5G -r /dev/mapper/rootvg-homelv
      # Extend root logical volume to remaining free space
      lvextend -l +100%free -r /dev/mapper/rootvg-rootlv
    fi
  fi
}

main() {
  if [[ "$SECRET_ENCRYPTION_ENABLED" == "true" ]]; then
    create_luks_volume
    populate_luks_volume
  fi
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

{% if salt['environ.get']('SALTBOOT_HTTPS_ENABLED') == 'true' %}
    create_cert_for_saltboot_tls
{% endif %}

    INSTANCE_ID=
    if [[ "$CLOUD_PLATFORM" == "AWS" ]]; then
      INSTANCE_ID="$(TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)"
    elif [[ "$CLOUD_PLATFORM" == "AZURE" ]]; then
      INSTANCE_ID="`wget -q -O - --header="Metadata: true" 'http://169.254.169.254/metadata/instance/compute/name?api-version=2017-08-01&format=text'`"
    elif [[ "$CLOUD_PLATFORM" == "GCP" ]]; then
      INSTANCE_ID="`wget -q -O - --header="Metadata-Flavor: Google" 'http://metadata.google.internal/computeMetadata/v1/instance/name'`"
    fi

    if [[ "$IS_PROXY_ENABLED" == "true" ]]; then
      setup_proxy
    fi

    # if CCMV1 -> setup CCM v1
    # if CCMV2 but not jumpgate -> setup CCMv2 on FreeIPA and data lake/data hub
    # if CCMV2_JUMPGATE -> agent should be started on FreeIPA only
    if [[ "$IS_CCM_ENABLED" == "true" ]]; then
      sudo update-crypto-policies --set DEFAULT:DISABLE-CBC
      sudo sed -i 's|CRYPTO_POLICY=|# CRYPTO_POLICY=|g' /etc/sysconfig/sshd
      sudo systemctl restart sshd
      setup_ccm
    elif [[ "$IS_CCM_V2_JUMPGATE_ENABLED" == "true" && "$IS_FREEIPA" == "true" ]]; then
      setup_ccmv2
    elif [[ "$IS_CCM_V2_ENABLED" == "true" && "$IS_CCM_V2_JUMPGATE_ENABLED" != "true" ]]; then
      setup_ccmv2
    fi

    resize_partitions

    echo $(date +%Y-%m-%d:%H:%M:%S) >> /var/cb-init-executed
  fi

  # Fix root ssh access for pre-7.2.8
  if [[ ! -d /yarn-private ]]; then
    if [ -f /etc/motd-login ]; then
      sed -i 's#command=".*" ssh-rsa#command="cat /etc/motd-login;sleep 5" ssh-rsa#' /root/.ssh/authorized_keys
    fi
  fi
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
