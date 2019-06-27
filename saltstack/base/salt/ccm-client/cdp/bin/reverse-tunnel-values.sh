#!/bin/bash -ux

TUNNEL_INITIATOR_ID= #ID of the tunnel initator. This is what will be used to query this endpoint.
ROLE= #This is what we will be using to query.
HOST_PORT= # Which port to do you want to tunnel onto?
CCM_SSH_PORT=8990 # The mina port. This is the default port number. No need to change this.
ENCIPHERED_PRIVATE_KEY=/tmp/enc.key # Put key here. Need not be encrypted for testing purposes.
HOST= # Destination of the mina service.
PUBLIC_KEY= # Path to the public key file of the mina service.
