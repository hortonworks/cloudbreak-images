#!/bin/bash

# This script is a wrapper for the Python interpreter used with ipaldaphagent so that we can run ipaldaphagent processes the correct SELinux domain

exec {{ pillar['salt_path'] }}/bin/python "$@"