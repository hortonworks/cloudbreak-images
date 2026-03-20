#!/bin/bash
set -ex -o pipefail

function attempt_connection_check()
{
    local initial_wait=1
    local wait_multiplier=2
    local current_wait_time=$initial_wait
    local max_wait_time=16
    local check_cmd="docker info"

    while [[ $current_wait_time -le $max_wait_time ]]
    do
        echo Checking if docker daemon is running.
        if $check_cmd
        then
            echo Docker daemon is running.
            exit 0
        fi
        echo Waiting for $current_wait_time
        sleep $current_wait_time
        current_wait_time=$(( current_wait_time*wait_multiplier))
    done
    exit 1
}

attempt_connection_check