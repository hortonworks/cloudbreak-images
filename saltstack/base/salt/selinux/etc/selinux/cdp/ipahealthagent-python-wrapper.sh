#!/bin/bash

# This script is a wrapper for the Python interpreter used with ipahealthagent so that we can run ipahealthagent processes the correct SELinux domain

exec /usr/bin/env python3 "$@"