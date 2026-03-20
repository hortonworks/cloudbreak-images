#!/bin/bash
set -ex -o pipefail

function check_docker_connection()
{   
    local current_wait_time=1 # seconds
    local wait_multiplier=2
    local check_cmd="docker info" # Exit code is non-zero if it can't connect to the daemon.
    local max_wait_time=$1 # Seconds
    while [[ $current_wait_time -le $max_wait_time ]]; do
        echo Checking if docker daemon is running.
        if $check_cmd; then
            echo Docker daemon is running.
            exit 0
        fi
        echo Waiting for $current_wait_time seconds for docker to come alive.
        sleep $current_wait_time
        current_wait_time=$(( current_wait_time*wait_multiplier ))
    done
    echo Docker daemon has failed to start within the specificed grace period. 
    exit 1
}

if [ -n "${MAX_BACKOFF_WAIT_TIME_SECONDS}" ]; then
    check_docker_connection $MAX_BACKOFF_WAIT_TIME_SECONDS
else
    echo MAX_BACKOFF_WAIT_TIME_SECONDS needs to be defined.
    exit 1
fi
