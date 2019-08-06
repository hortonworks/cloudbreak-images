#!/bin/bash -ux

CCM_HOST= # The host endpoint for the CCM (minasshd) service.
CCM_SSH_PORT=8990 # The port on which the CCM (minasshd) service listens for SSH connections.
CCM_PUBLIC_KEY_FILE= # The path to the public key file for the CCM (minasshd) service.
CCM_TUNNEL_INITIATOR_ID= # The ID of the tunnel initator. This is what other services will use to locate this host endpoint.
CCM_ENCIPHERED_PRIVATE_KEY=/etc/ccm/ccm-private-key.enc # The private key that the CCM (minasshd) service will use to authenticate this instance (encrypted for production, but not necessarily for testing).
CCM_TUNNEL_ROLE= # The identifier for the specific service for which the tunnel is being created.
CCM_TUNNEL_SERVICE_PORT= # The service endpoint to be tunneled.
