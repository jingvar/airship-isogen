#!/bin/bash

set -xe

CONFIG=/config/cloud-config.yml

if [ ! -f $CONFIG ] ;then
    echo "$CONFIG not found"
    exit 1
fi

source functions.sh

_debootstrap

_packets_install

cp /builder/interfaces.config $HOME/LIVE_BOOT/chroot/etc/network/interfaces

_render_template /builder/70-persistent-net.rules > $HOME/LIVE_BOOT/chroot/etc/udev/rules.d/70-persistent-net.rules

cp $CONFIG $HOME/LIVE_BOOT/chroot/etc/cloud/cloud.cfg.d/95_no_cloud_ds.cfg

_make_kernel
_grub_install
_make_iso
