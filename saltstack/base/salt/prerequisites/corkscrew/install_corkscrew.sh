#!/bin/bash
wget https://github.com/bryanpkc/corkscrew/archive/v2.0.zip -O /tmp/corkscrew.zip
unzip /tmp/corkscrew.zip -d /tmp
cd /tmp/corkscrew-2.0/
autoreconf --install
./configure
make
sudo make install
