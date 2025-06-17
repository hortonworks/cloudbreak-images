#!/bin/bash

exec {{ pillar['salt_path'] }}/bin/python {{ pillar['salt_path'] }}/bin/salt-minion "$@"
