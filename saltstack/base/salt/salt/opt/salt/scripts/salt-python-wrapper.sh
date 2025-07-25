#!/bin/bash

# This script is a wrapper for the Python interpreter used with Salt so that we can run Salt processes the correct SELinux domain

exec {{ pillar['salt_path'] }}/bin/python "$@"
