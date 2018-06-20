#!/bin/sh

echo "Starting Virtual IP"

# Mac
sudo ifconfig en0 alias 172.16.31.32/24

# Linux
# ifconfig eth0:0 172.16.31.32/24

# Solaris

echo "Done"
