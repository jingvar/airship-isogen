#!/bin/bash

set -xe
IFS=':' read -ra ADDR <<<$(yq r $BUILDER_CONFIG container.volume)
VOLUME=${ADDR[1]}

USER_DATA=$VOLUME/$(yq r $BUILDER_CONFIG builder.userDataFileName)
NET_CONFIG=$VOLUME/$(yq r $BUILDER_CONFIG builder.networkConfigFileName)

if [ ! -f $USER_DATA ] ;then
    echo "$USER_DATA not found"
    exit 1
fi
if [ ! -f $NET_CONFIG ] ;then
    echo "$NET_CONFIG not found"
    exit 1
fi

source $(dirname $0)/functions.sh

#_get_mac_from_config

_debootstrap

cat $(dirname $0)/packages_install.sh | chroot $HOME/LIVE_BOOT/chroot

#cp /builder/interfaces.config $HOME/LIVE_BOOT/chroot/etc/network/interfaces

cp $USER_DATA $HOME/LIVE_BOOT/chroot/etc/cloud/cloud.cfg.d/user-data.cfg
cp $NET_CONFIG $HOME/LIVE_BOOT/chroot/etc/cloud/cloud.cfg.d/network-config.cfg
echo "datasource_list: [ NoCloud, None ]" > $HOME/LIVE_BOOT/chroot/etc/cloud/cloud.cfg.d/95_no_cloud_ds.cfg

_make_kernel
_grub_install
_make_iso

OUTPUT=$(yq r $BUILDER_CONFIG builder.outputMetadataFileName)
HOST_PATH=${ADDR[0]}
_make_metadata $VOLUME/$OUTPUT $HOST_PATH
