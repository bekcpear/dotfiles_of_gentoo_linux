#!/bin/bash
#

set -e

make clean
make -j30
make modules_install
make install
genkernel --kernel-config=/usr/src/linux/.config initramfs
grub-mkconfig -o /boot/grub/grub.cfg
emerge -vj @module-rebuild
