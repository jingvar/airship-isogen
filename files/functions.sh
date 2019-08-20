#functions

function _get_mac_from_config () {
  ACCESS_MAC_ADDRESS=`yq r ${CONFIG} "network.config[0].mac_address"`
}

function _render_template() {
  file_path=$1
  tmpl=$(cat ${file_path})
  eval "echo \"${tmpl}\""
}

function _debootstrap (){
  debootstrap \
    --arch=amd64 \
    --variant=minbase \
    buster \
    $HOME/LIVE_BOOT/chroot \
    http://ftp.debian.org/debian/
}

function _packets_install() {
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
    echo 'root:r00tme' | chpasswd
    rm -rf /var/lib/apt/lists/*
EOF
}

function _make_kernel(){
  mkdir -p $HOME/LIVE_BOOT/{scratch,image/live}
  mksquashfs \
    $HOME/LIVE_BOOT/chroot \
    $HOME/LIVE_BOOT/image/live/filesystem.squashfs \
    -e boot

  cp $HOME/LIVE_BOOT/chroot/boot/vmlinuz-* \
     $HOME/LIVE_BOOT/image/vmlinuz && \
  cp $HOME/LIVE_BOOT/chroot/boot/initrd.img-* \
     $HOME/LIVE_BOOT/image/initrd
}


function _grub_install (){
  cp /builder/grub.conf $HOME/LIVE_BOOT/scratch/grub.cfg

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
}

function _make_iso(){
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
    -output "/config/debian-custom.iso" \
    -graft-points \
        "${HOME}/LIVE_BOOT/image" \
        /boot/grub/bios.img=$HOME/LIVE_BOOT/scratch/bios.img
}
