#!/usr/bin/env bash
#
# openstack-post-burn-steps.sh
#
# Post-burn step for the OpenStack (openstack-redhat9) packer build.
# Locates the freshly burnt image by name and prints its properties using the
# glance CLI. The CLI runs inside the cloudbreak-openstack-cli-tools container
# image (built/published from tools/cloudbreak-openstack-cli-tools), which is
# pushed to the company registry and therefore available to the local docker
# daemon on the build host.
#
# Expected environment (exported by the Makefile / build-openstack-redhat9):
#   IMAGE_NAME                   - name of the image just burnt (packer image_name)
#   OPENSTACK_AUTH_URL           - keystone v3 endpoint
#   OPENSTACK_USERNAME
#   OPENSTACK_PASSWORD
#   OPENSTACK_PROJECT_NAME       - tenant / project
#   OPENSTACK_PROJECT_DOMAIN_ID  - default: "default"
#   OPENSTACK_USER_DOMAIN_ID     - default: "default"
#   OPENSTACK_REGION_NAME
# Optional:
#   GLANCE_CLI_VERSION           - image tag to run (default: "dev")
#   GLANCE_CLI_IMAGE             - full override of the container image reference

set -euo pipefail

: "${IMAGE_NAME:?IMAGE_NAME is required (name of the image being burnt)}"
: "${OPENSTACK_AUTH_URL:?OPENSTACK_AUTH_URL is required}"
: "${OPENSTACK_USERNAME:?OPENSTACK_USERNAME is required}"
: "${OPENSTACK_PASSWORD:?OPENSTACK_PASSWORD is required}"
: "${OPENSTACK_PROJECT_NAME:?OPENSTACK_PROJECT_NAME is required}"

OPENSTACK_PROJECT_DOMAIN_ID="${OPENSTACK_PROJECT_DOMAIN_ID:-default}"
OPENSTACK_USER_DOMAIN_ID="${OPENSTACK_USER_DOMAIN_ID:-default}"
OPENSTACK_REGION_NAME="${OPENSTACK_REGION_NAME:-}"

# Published by tools/cloudbreak-openstack-cli-tools (see its Makefile: `make release`).
GLANCE_CLI_REPO="docker-sandbox.infra.cloudera.com/cloudbreak-tools/cloudbreak-openstack-cli-tools"
GLANCE_CLI_VERSION="${GLANCE_CLI_VERSION:-dev}"
GLANCE_CLI_IMAGE="${GLANCE_CLI_IMAGE:-${GLANCE_CLI_REPO}:${GLANCE_CLI_VERSION}}"

# Map the repo's OPENSTACK_* variables onto the standard OS_* variables that the
# glance / openstack clients read from the environment inside the container.
os_env=(
    -e "OS_AUTH_URL=${OPENSTACK_AUTH_URL}"
    -e "OS_USERNAME=${OPENSTACK_USERNAME}"
    -e "OS_PASSWORD=${OPENSTACK_PASSWORD}"
    -e "OS_PROJECT_NAME=${OPENSTACK_PROJECT_NAME}"
    -e "OS_PROJECT_DOMAIN_ID=${OPENSTACK_PROJECT_DOMAIN_ID}"
    -e "OS_USER_DOMAIN_ID=${OPENSTACK_USER_DOMAIN_ID}"
    -e "OS_REGION_NAME=${OPENSTACK_REGION_NAME}"
    -e "OS_IDENTITY_API_VERSION=3"
    -e "OS_IMAGE_API_VERSION=2"
)

run_glance() {
    docker run --rm "${os_env[@]}" "${GLANCE_CLI_IMAGE}" glance "$@"
}

run_openstack() {
    docker run --rm "${os_env[@]}" "${GLANCE_CLI_IMAGE}" openstack "$@"
}

echo "Locating OpenStack image by name: ${IMAGE_NAME}"
# --name is a server-side exact-match filter; -f value -c ID prints only IDs.
mapfile -t image_ids < <(run_openstack image list --name "${IMAGE_NAME}" -f value -c ID | tr -d '\r')

if [[ "${#image_ids[@]}" -eq 0 || -z "${image_ids[0]}" ]]; then
    echo "ERROR: no OpenStack image found with name '${IMAGE_NAME}'" >&2
    exit 1
fi

if [[ "${#image_ids[@]}" -gt 1 ]]; then
    echo "WARNING: ${#image_ids[@]} images match name '${IMAGE_NAME}'; using the first" >&2
fi

IMAGE_ID="${image_ids[0]}"
echo "Found image '${IMAGE_NAME}' -> ${IMAGE_ID}"

echo "Image properties (glance image-show):"
run_glance image-show "${IMAGE_ID}"
