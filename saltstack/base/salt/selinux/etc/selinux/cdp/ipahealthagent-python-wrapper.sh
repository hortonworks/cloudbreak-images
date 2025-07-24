#!/bin/bash

# This script is a wrapper for the Python interpreter used with IPA so that we can run IPA processes the correct SELinux domain

exec {{ pillar['salt_path'] }}/bin/python "$@"