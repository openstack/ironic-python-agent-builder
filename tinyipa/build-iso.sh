#!/bin/bash

set -ex
WORKDIR=$(readlink -f $0 | xargs dirname)
SYSLINUX_VERSION="6.03"
SYSLINUX_URL="https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-${SYSLINUX_VERSION}.tar.gz"

source ${WORKDIR}/common.sh

cd ${WORKDIR}/build_files
wget -N $SYSLINUX_URL && tar zxf syslinux-${SYSLINUX_VERSION}.tar.gz

cd $WORKDIR
rm -rf newiso
mkdir -p newiso/boot/isolinux
cp build_files/syslinux-${SYSLINUX_VERSION}/bios/core/isolinux.bin newiso/boot/isolinux/.
cp build_files/isolinux.cfg newiso/boot/isolinux/.
cp tinyipa${BRANCH_EXT}.gz newiso/boot/corepure64.gz
cp tinyipa${BRANCH_EXT}.vmlinuz newiso/boot/vmlinuz64

set +e
ISO_BUILDER=""

for builder in mkisofs genisoimage xorrisofs; do
    if $($builder --help); then
        ISO_BUILDER=$builder
    fi
done
if [ -z "$ISO_BUILDER" ]; then
   echo "Please install a ISO filesystem builder utility such as mkisofs, genisoimage, or xorrisofs."
   exit 1
fi

set -e
$ISO_BUILDER -l -r -J -R -V TC-custom -no-emul-boot -boot-load-size 4 -boot-info-table -b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat -o tinyipa.iso newiso
