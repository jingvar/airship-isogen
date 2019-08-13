#!/bin/bash

set -xe

ACCESS_SSH_PUB_KEY=${1:-ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDEMMYsge3feKSQVDmGEe+14KAthSXWcqVrI+5+QBoO8pu7z6dINGE3w5jatICz9Lm92mXXZN1teM52bCWpDRyjt8L3jKfgHPeHoN6DSbQqKQOYDvl0IsUixUH7f2McSASnwP15ecj0uLXXGLmoqL5OZKje8ldzgS3TDLJDiqM7auYuFx4IggQSay2dX+JfwGv/OW0NeHNCqcv+EQ1LW7Y0rhIDYZ5nZWLjSMiJhvX7kITdBqKHrEUscWrDwSEAd2bCROFDMDxg70P8PkiTmkonaYzOVVDzovHI64SMggfL9zLYHueTsC0yoylWwX/u9WaqK2NaDvyH3zmNuacr6wmz}
ACCESS_MAC_ADDRESS=${2:-52:54:00:18:6e:50}
ACCESS_IP_CIDR=${3:-172.18.164.37/27}
ACCESS_GW=${4:-172.18.164.33}
DNS_SERVER=${5:-8.8.8.8}

function render_template() {
    file_path=$1
    tmpl=$(cat ${file_path})
    eval "echo \"${tmpl}\""
}

debootstrap \
    --arch=amd64 \
    --variant=minbase \
    buster \
    $HOME/LIVE_BOOT/chroot \
    http://ftp.debian.org/debian/

cat  << EOF | chroot $HOME/LIVE_BOOT/chroot

set -xe

echo "debian-live" > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts

apt-get update && apt-get install  -y --no-install-recommends \
    linux-image-amd64 \
    live-boot \
    systemd-sysv

apt-get install -y --no-install-recommends \
    cloud-init \
    apt-transport-https \
    openssh-server \
    curl 

echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
echo "deb [arch=amd64] https://download.docker.com/linux/debian buster stable" > /etc/apt/sources.list.d/docker.list

apt-get update --allow-insecure-repositories && apt-get install  -y --no-install-recommends --allow-unauthenticated \
    docker-ce \
    kubelet \
    kubeadm \
    kubectl

echo 'root:r00tme' | chpasswd

rm -rf /var/lib/apt/lists/*

EOF

cp /builder/files/interfaces.config $HOME/LIVE_BOOT/chroot/etc/network/interfaces
render_template /builder/templates/70-persistent-net.rules > $HOME/LIVE_BOOT/chroot/etc/udev/rules.d/70-persistent-net.rules
render_template /builder/templates/cloud-config.yml > $HOME/LIVE_BOOT/chroot/etc/cloud/cloud.cfg.d/95_no_cloud_ds.cfg

mkdir -p $HOME/LIVE_BOOT/{scratch,image/live}
mksquashfs \
    $HOME/LIVE_BOOT/chroot \
    $HOME/LIVE_BOOT/image/live/filesystem.squashfs \
    -e boot

cp $HOME/LIVE_BOOT/chroot/boot/vmlinuz-* \
    $HOME/LIVE_BOOT/image/vmlinuz && \
cp $HOME/LIVE_BOOT/chroot/boot/initrd.img-* \
    $HOME/LIVE_BOOT/image/initrd

cat <<'EOF' >$HOME/LIVE_BOOT/scratch/grub.cfg

search --set=root --file /DEBIAN_CUSTOM

insmod all_video

set default="0"
set timeout=30

menuentry "Debian Live" {
    linux /vmlinuz boot=live quiet nomodeset ip=frommedia
    initrd /initrd
}
EOF

touch $HOME/LIVE_BOOT/image/DEBIAN_CUSTOM

grub-mkstandalone \
    --format=i386-pc \
    --output=$HOME/LIVE_BOOT/scratch/core.img \
    --install-modules="linux normal iso9660 biosdisk memdisk search tar ls" \
    --modules="linux normal iso9660 biosdisk search" \
    --locales="" \
    --fonts="" \
    "boot/grub/grub.cfg=$HOME/LIVE_BOOT/scratch/grub.cfg"

cat \
    /usr/lib/grub/i386-pc/cdboot.img \
    $HOME/LIVE_BOOT/scratch/core.img \
> $HOME/LIVE_BOOT/scratch/bios.img

xorriso \
    -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "DEBIAN_CUSTOM" \
    --grub2-boot-info \
    --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -eltorito-boot \
        boot/grub/bios.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --eltorito-catalog boot/grub/boot.cat \
    -output "/out/debian-custom.iso" \
    -graft-points \
        "${HOME}/LIVE_BOOT/image" \
        /boot/grub/bios.img=$HOME/LIVE_BOOT/scratch/bios.img
