#!/bin/bash

for pkg in `dpkg --list | grep "^rc" | awk '{print $2}'`; do dpkg -P $pkg; done
aptitude keep-all
aptitude unmarkauto ~M
apt-get clean
updatedb

