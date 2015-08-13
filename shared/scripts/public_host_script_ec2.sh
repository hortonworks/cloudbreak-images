#!/bin/bash
echo $(curl -s -m 5 http://169.254.169.254/latest/meta-data/public-ipv4)