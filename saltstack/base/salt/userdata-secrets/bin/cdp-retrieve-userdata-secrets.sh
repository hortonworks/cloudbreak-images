#!/bin/bash

set -e +x

# DO NOT EXPORT environment variables in this file, because this file is called with `source` in `user-data-helper.sh`!

log() {
  echo "$(date +"%F-%T") $*"
}

# This function implements basically the same exponential backoff strategy as the aws cli in standard retry mode
retry_until_non_placeholder_value() {
  local BASE_FACTOR=2
  local MAX_BACKOFF=20
  local MAX_ATTEMPT=15
  local ACCESS_DENIED_EXIT_CODE=254

  local total_wait_time=0
  local timeout=1
  local attempt=1
  local non_transient_aws_service_error_count=0

  set +e
  SECRET_STRING="$("$@")"
  local exit_code=$?
  set -e
  while [[ "$SECRET_STRING" == "PLACEHOLDER" || "$exit_code" == "$ACCESS_DENIED_EXIT_CODE" ]]; do
    if (( attempt > MAX_ATTEMPT )); then
      log "Maximum number of retry attempts reached while waiting for userdata secret to update! Total wait time was $total_wait_time seconds. Exiting..."
      exit 1
    fi
    if [[ "$exit_code" == "$ACCESS_DENIED_EXIT_CODE" ]]; then
      non_transient_aws_service_error_count=$(( non_transient_aws_service_error_count + 1 ))
      log "Getting the userdata secret failed with a non-transient error. See the error returned by aws-cli above! "
    else
      log "Userdata secret still has PLACEHOLDER value."
    fi

    log "Waiting $timeout seconds until the next attempt to retrieve the secret."
    sleep $timeout

    total_wait_time=$(( total_wait_time + timeout ))
    attempt=$(( attempt + 1 ))
    timeout=$(( timeout * BASE_FACTOR > MAX_BACKOFF ? MAX_BACKOFF : timeout * BASE_FACTOR ))

    set +e
    SECRET_STRING="$("$@")"
    exit_code=$?
    set -e
  done
  log "Total number of non-transient AWS errors: $non_transient_aws_service_error_count."
  log "Userdata secret's value was retrieved after waiting $total_wait_time seconds."
}

# Helper function for passing aws-cli params related to the built-in retry mechanism, and param to instruct aws-cli to use FIPS endpoints
aws_with_cli_params() {
  # See: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-retries.html
  # aws cli with standard retry mode uses an exponential backoff with a base factor of 2 and a maximum backoff time of 20 seconds
  local aws_retry_mode=standard
  # AWS_MAX_ATTEMPTS=15 would mean a maximum wait time of approximately 4 minutes per aws cli command
  local aws_max_attempts=15

  AWS_RETRY_MODE="$aws_retry_mode" AWS_MAX_ATTEMPTS="$aws_max_attempts" AWS_USE_FIPS_ENDPOINT=true "$@"
}

# Intermittent issues like throttling of AWS APIs are handled by the built in retry mechanism of the aws cli.
# Waiting for CB to update the secret's value to the actual secrets is handled by the `retry_until_non_placeholder_value` function.
main() {
  log "$(basename $0) Start"

  if [[ -z "$USERDATA_SECRET_ID" ]]; then
    log "USERDATA_SECRET_ID is empty. Cannot retrieve userdata secrets!"
    exit 1
  fi

  if [[ "$CLOUD_PLATFORM" == "AWS" ]]; then
    log "Retrieving userdata secrets..."
    retry_until_non_placeholder_value \
    aws_with_cli_params \
    aws --debug secretsmanager get-secret-value \
      --output text \
      --query SecretString \
      --secret-id "$USERDATA_SECRET_ID"
    eval "$SECRET_STRING"
    log "Successfully retrieved userdata secrets!"

    log "Deleting secret associated with this instance..."
    aws_with_cli_params \
    aws --debug secretsmanager delete-secret \
      --force-delete-without-recovery \
      --secret-id "$USERDATA_SECRET_ID"
    log "Successfully deleted secret associated with this instance!"
  else
    log "Userdata secret retrieval not implemented for CLOUD_PLATFORM $CLOUD_PLATFORM."
    exit 2
  fi

  log "$(basename $0) Finish"
}

main
