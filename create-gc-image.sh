#!/bin/bash

set -eo pipefail
if [[ "$TRACE" ]]; then
    : ${START_TIME:=$(date +%s)}
    export START_TIME
    export PS4='+ [TRACE $BASH_SOURCE:$LINENO][ellapsed: $(( $(date +%s) -  $START_TIME ))] '
    set -x
fi

: ${DEBUG:=1}

debug() {
    [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

main() {
    if [[ ${PACKER_BUILDER_TYPE:? required} == "googlecompute" ]]; then
        mkdir -p /tmp/imagebundle
        gcimagebundle -d /dev/sda -o /tmp/imagebundle --fssize=16106127360 --log_file=/tmp/imagebundle/create_imagebundle.log
        curl -O https://storage.googleapis.com/pub/gsutil.tar.gz
        tar xfz gsutil.tar.gz -C $HOME
        export PATH=${PATH}:$HOME/gsutil
        gsutil cp -a public-read /tmp/imagebundle/*.image.tar.gz gs://sequenceiqimage/"${PACKER_IMAGE_NAME:?required}".tar.gz
        rm -rf /tmp/imagebundle
    fi
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
