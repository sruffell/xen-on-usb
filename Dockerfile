FROM debian:buster

RUN apt update; apt install -y \
    xen-hypervisor-4.11-amd64 \
    parted \
    dosfstools \
    git \
    automake \
    build-essential \
    autopoint \
    bison \
    pkg-config \
    flex \
    liblzma-dev \
    libfuse-dev \
    libfreetype6-dev

RUN mkdir -p /usr/local/src; \
    cd /usr/local/src; \
    git clone -b grub-2.04 https://git.savannah.gnu.org/git/grub.git

RUN cd /usr/local/src/grub; ./bootstrap

RUN mkdir -p /usr/local/src/grub-x86_64-efi; \
    cd /usr/local/src/grub-x86_64-efi; \
    ../grub/configure --with-platform=efi --target=x86_64; \
    make install -j $(grep '^processor' /proc/cpuinfo  | wc -l); \
    mkdir -p /usr/local/src/grub-i386-pc; \
    cd /usr/local/src/grub-i386-pc; \
    ../grub/configure --with-platform=pc --target=i386; \
    make install -j $(grep '^processor' /proc/cpuinfo  | wc -l)
