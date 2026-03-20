#!/bin/bash
set -ex -o pipefail

function attempt_connection_check()
{   
    local current_wait_time=1 # seconds
    local wait_multiplier=2
    local max_wait_time=2 # seconds
    local check_cmd="docker info" # Fails if can't connect to the daemon with a non-zero exit code.

    while [[ $current_wait_time -le $max_wait_time ]]; do
        echo Checking if docker daemon is running.
        if $check_cmd; then
            echo Docker daemon is running.
            exit 0
        fi
        echo Waiting for $current_wait_time
        sleep $current_wait_time
        current_wait_time=$(( current_wait_time*wait_multiplier ))
    done
    exit 1
}

attempt_connection_check
