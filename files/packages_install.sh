#!/bin/bash
set -xe
echo "debian-live" > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "deb http://ftp.debian.org/debian unstable main" >> /etc/apt/sources.list
apt-get update && apt-get install  -y --no-install-recommends \
   linux-image-amd64 \
   live-boot \
   systemd-sysv
apt-get install -y --no-install-recommends \
      cloud-init \
      apt-transport-https \
      openssh-server \
      curl
echo 'root:r00tme' | chpasswd
rm -rf /var/lib/apt/lists/*
