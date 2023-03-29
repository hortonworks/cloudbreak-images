#!/bin/bash

echo "FIPS mode setup"


    echo "Set FIPS enabled and then reboot..."
    fips-mode-setup --enable
    reboot
