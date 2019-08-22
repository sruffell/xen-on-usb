Installing Xen on a USB stick
=============================

This is a small configuration utility that helps get Xen installed on a USB
stick and then launch into a Linux shell in Dom0. Currently, the linux shell
is the rescue mode of the debian netinstall, and so it does not have any Xen
utilitilies in it.

I set it up this way since I was having trouble using the default grub on my
system. By building grub in the container I could boot the EFI target on the
multiple machines I was testing on (however, legacy boot did not work on one
of them)

## Installation

- Download mini.iso.
```
        $ curl -O http://ftp.debian.org/debian/dists/buster/main/installer-amd64/current/images/netboot/mini.iso
```

- Build the docker image.
```
        $ docker build -t xen-on-usb:latest - < Dockerfile
```

- Insert a USB stick, 4GB should be large enough, into your system. Take note
- Run the partition script in the docker container
```
        $ docker run --privileged -ti -v $(pwd):/source xen-on-usb:latest /source/partition-usb.sh [usb device file] 
```

## Running

You *should* be able to boot this both in BIOS boot or EFI boot modes. This
will start up the Debian netinstall image in rescue mode. You can get to a
console from the rescue mode image by pressing ALT-F2.

From the console, you can confirm that you're running under xen / efi by
checking the output of `dmesg | grep -e xen -e efi`
