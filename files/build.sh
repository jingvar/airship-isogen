#!/bin/bash

set -xe

CONFIG=/config/cloud-config.yml

if [ ! -f $CONFIG ] ;then
    echo "$CONFIG not found"
    exit 1
fi

source $(dirname $0)/functions.sh

_get_mac_from_config

_debootstrap

cat $(dirname $0)/packages_install.sh | chroot $HOME/LIVE_BOOT/chroot

cp /builder/interfaces.config $HOME/LIVE_BOOT/chroot/etc/network/interfaces

_render_template /builder/70-persistent-net.rules > $HOME/LIVE_BOOT/chroot/etc/udev/rules.d/70-persistent-net.rules

cp $CONFIG $HOME/LIVE_BOOT/chroot/etc/cloud/cloud.cfg.d/95_no_cloud_ds.cfg

_make_kernel
_grub_install
_make_iso
_make_metadata /config/output-metadata.yaml
