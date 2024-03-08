#!/usr/bin/env bash

CONNECTION_TIMEOUT=5
LOG_FILE=/var/log/ccmv2-connectivity-check.log

function log() {
    MESSAGE=$1
    echo "$(date '+%d/%m/%Y %H:%M:%S') - $MESSAGE " >> $LOG_FILE
}

function prefix_to_bit_netmask() {
    local prefix=$1;
    local shift=$(( 32 - prefix ));

    local bitmask=""
    for (( i=0; i < 32; i++ )); do
        num=0
        if [[ $i -lt $prefix ]]; then
            num=1
        fi

        space=
        if [[ $(( i % 8 )) -eq 0 ]]; then
            space=" ";
        fi

        bitmask="${bitmask}${space}${num}"
    done
    echo $bitmask
}

function bit_netmask_to_wildcard_netmask() {
    local bitmask=$1;
    local wildcard_mask=
    for octet in $bitmask; do
        wildcard_mask="${wildcard_mask} $(( 255 - 2#$octet ))"
    done
    echo $wildcard_mask;
}

function check_net_boundary() {
    local net=$1;
    local wildcard_mask=$2;
    local is_correct=1;
    for (( i = 1; i <= 4; i++ )); do
        net_octet=$(echo $net | cut -d '.' -f $i)
        mask_octet=$(echo $wildcard_mask | cut -d ' ' -f $i)
        if [[ $mask_octet -gt 0 ]]; then
            if [[ $(( $net_octet&$mask_octet )) -ne 0 ]]; then
                is_correct=0;
            fi
        fi
    done
    echo $is_correct;
}

function expand {
    local net=$(echo $1 | cut -s -d '/' -f 1);
    local prefix=$(echo $1 | cut -s -d '/' -f 2);

    if [[ -z "$net" || -z "$prefix" ]] ; then
        log "Input $1 is not a CIDR"
        printf '{"result": "%s", "reason": "Input [%s] is not a CIDR"}' "FAILED" "$1"
        exit 1
    fi

    local bit_netmask=$(prefix_to_bit_netmask $prefix);
    local wildcard_mask=$(bit_netmask_to_wildcard_netmask "$bit_netmask");
    local is_net_boundary=$(check_net_boundary $net "$wildcard_mask");

    if [[ $is_net_boundary -ne 1 ]] ; then
        log "CIDR base address $1 did not start at a subnet boundary"
        printf '{"result": "%s", "reason": "CIDR base address %s did not start at a subnet boundary"}' "FAILED" "$1"
        exit 1
    fi

    local str=
    for (( i = 1; i <= 4; i++ )); do
            range=$(echo $net | cut -d '.' -f $i)
            mask_octet=$(echo $wildcard_mask | cut -d ' ' -f $i)
            if [ $mask_octet -gt 0 ]; then
                    range="{$range..$(( $range | $mask_octet ))}";
            fi
            str="${str} $range"
    done
    local ips=$(echo $str | sed "s, ,\\.,g");
    eval echo $ips
}

function try_connect {
    local ip=$1
    log "Trying to connect to $ip via HTTPS"
    if [[ -f /etc/cdp/proxy.env ]]; then
      source /etc/cdp/proxy.env
    fi
    curl --connect-timeout $CONNECTION_TIMEOUT -sk https://$ip > /dev/null
    local status=$?
    if [[ $status -eq 0 ]]; then
        log "Connection to $ip was successful"
    else
        log "Connection to $ip failed"
    fi
    return $status
}

function main {
    local cidrs=$@
    local did_enter=0
    for cidr in ${cidrs[@]}; do
        did_enter=1
        local ips
        ips=$(expand "$cidr")
        if [[ $? -ne 0 ]]; then
            echo $ips
            exit 1
        fi
        for ip in $ips; do
            try_connect $ip
            if [[ $? -eq 0 ]]; then
                echo '{"result": "SUCCESSFUL", "reason": "Connection to a CCMv2 server endpoint was successful."}'
                exit 0
            fi
        done
    done
    if [[ $did_enter -eq 1 ]]; then
        log "No connectivity is possible in the whole CIDR range."
        echo '{"result": "FAILED", "reason": "No connectivity is possible to CCMv2 server endpoints in the whole CIDR range."}'
        exit 2
    fi
}

main "$@"
