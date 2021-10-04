#!/bin/bash
#

set -e

make clean
make -j30
make modules_install
make install
emerge -vj @module-rebuild
