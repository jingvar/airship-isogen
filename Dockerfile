FROM debian:stable

RUN apt-get update && apt-get install -y \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools \
 && rm -rf /var/lib/apt/lists/*
 
COPY ./files/build.sh /builder/
COPY ./files/70-persistent-net.rules /builder/
COPY ./files/interfaces.config /builder/
COPY ./files/functions.sh /builder/
COPY ./files/grub.conf /builder/

ADD https://github.com/mikefarah/yq/releases/download/2.4.0/yq_linux_amd64 /builder/
RUN install /builder/yq_linux_amd64 /bin/yq

CMD /bin/bash /builder/build.sh
