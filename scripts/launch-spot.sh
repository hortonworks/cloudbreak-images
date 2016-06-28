#!/bin/bash

set -eo pipefail
if [[ "$TRACE" ]]; then
    : ${START_TIME:=$(date +%s)}
    export START_TIME
    export PS4='+ [TRACE $BASH_SOURCE:$LINENO][ellapsed: $(( $(date +%s) -  $START_TIME ))] '
    set -x
fi

debug() {
  [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}


get_launch_spec() {
cat << EOF
{
  "ImageId": "$SPOT_AMI",
  "KeyName": "$SPOT_KEY",
  "InstanceType": "$SPOT_TYPE"
}
EOF
}

spot-request() {
    local validUntil=$(date -v+${SPOT_HOURS}H +%Y-%m-%dT%H:%M:%S%z)
    debug "create sport request until: $validUntil"

    local spotReq=$(
      aws ec2 request-spot-instances \
        --spot-price  $SPOT_PRICE \
        --valid-until ${validUntil}\
        --launch-specification file://<(get_launch_spec) \
        --query SpotInstanceRequests[0].SpotInstanceRequestId \
        --instance-count $SPOT_COUNT \
        --out text
    )

    debug "spotReq=$spotReq"
    debug "wait for fulfilled status ..."
    local status=$(aws ec2 describe-spot-instance-requests --spot-instance-request-ids $spotReq --query SpotInstanceRequests[0].Status.Code --out text)
    while ! [[ $status == "fulfilled" ]]; do
        echo -n .
        sleep 3
        status=$(aws ec2 describe-spot-instance-requests --spot-instance-request-ids $spotReq --query SpotInstanceRequests[0].Status.Code --out text)
        debug "spot status: $status"
    done

    local instance=$(aws ec2 describe-spot-instance-requests --spot-instance-request-ids $spotReq --query SpotInstanceRequests[0].InstanceId --out text)
    debug "instance=$instance"

    debug "tag instance with owner=$OWNER"
    aws ec2 create-tags --resources $instance --tags Key=owner,Value=$OWNER Key=Owner,Value=$OWNER Key=spot,Value=$SPOT_PRICE

    local ip=$(aws ec2 describe-instances --instance-ids $instance --query Reservations[0].Instances[0].PublicIpAddress --out text)
    debug "ip=$ip"

    echo =====
    echo "ssh cloudbreak@$ip"
}

main() {
  : ${DEBUG:=1}
  : ${SPOT_COUNT:=1}
  : ${SPOT_HOURS:=8}
  : ${SPOT_PRICE:=0.1}
  : ${SPOT_TYPE:=m4.large}
  : ${SPOT_KEY:=seq-master}
  : ${SPOT_AMI:=ami-40138c33}
  : ${OWNER:=$USER}

  for v in ${!SPOT_*}; do
      debug $v=${!v}
  done

  spot-request
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@" || true
