#!/bin/bash

set -ex
WORKDIR=$(readlink -f $0 | xargs dirname)
source ${WORKDIR}/tc-mirror.sh
BUILDDIR="$WORKDIR/tinyipabuild"
TINYCORE_MIRROR_URL=${TINYCORE_MIRROR_URL:-}
TINYIPA_REQUIRE_BIOSDEVNAME=${TINYIPA_REQUIRE_BIOSDEVNAME:-false}
TINYIPA_REQUIRE_IPMITOOL=${TINYIPA_REQUIRE_IPMITOOL:-true}
IRONIC_LIB_SOURCE=${IRONIC_LIB_SOURCE:-}
USE_PYTHON3=${USE_PYTHON3:-True}
TC_RELEASE="10.x"

TGT_RELEASE="v1.0.79"
QEMU_RELEASE="v3.1.1"
LSHW_RELEASE="B.02.18"

BIOSDEVNAME_RELEASE="0.7.2"
IPMITOOL_RELASE="1_8_18"

# PYTHON_EXTRA_SOURCES_DIR_LIST is a csv list of python package dirs to include
PYTHON_EXTRA_SOURCES_DIR_LIST=${PYTHON_EXTRA_SOURCES_DIR_LIST:-}

CHROOT_PATH="/tmp/overides:/usr/local/sbin:/usr/local/bin:/apps/bin:/usr/sbin:/usr/bin:/sbin:/bin"
CHROOT_CMD="sudo chroot $BUILDDIR /usr/bin/env -i PATH=$CHROOT_PATH http_proxy=$http_proxy https_proxy=$https_proxy no_proxy=$no_proxy"

TC=1001
STAFF=50

function clone_single_branch {
    git clone --branch $3 --depth=1 $1 $2
}

echo "Building tinyipa:"

# Ensure we have an extended sudo to prevent the need to enter a password over
# and over again.
sudo -v

# If an old build directory exists remove it
if [ -d "$BUILDDIR" ]; then
    sudo rm -rf "$BUILDDIR"
fi

##############################################
# Download and Cache Tiny Core Files
##############################################

# Find a working TC mirror if none is explicitly provided
choose_tc_mirror

cd $WORKDIR/build_files
wget -N $TINYCORE_MIRROR_URL/$TC_RELEASE/x86_64/release/distribution_files/corepure64.gz
wget -N $TINYCORE_MIRROR_URL/$TC_RELEASE/x86_64/release/distribution_files/vmlinuz64
cd $WORKDIR

########################################################
# Build Required Python Dependecies in a Build Directory
########################################################

# Make directory for building in
mkdir "$BUILDDIR"

# Extract rootfs from .gz file
( cd "$BUILDDIR" && zcat $WORKDIR/build_files/corepure64.gz | sudo cpio -i -H newc -d )

# Configure mirror
sudo sh -c "echo $TINYCORE_MIRROR_URL > $BUILDDIR/opt/tcemirror"

# Download TGT, Qemu-utils, Biosdevname and IPMItool source
clone_single_branch "https://github.com/fujita/tgt.git" "${BUILDDIR}/tmp/tgt" "$TGT_RELEASE"
clone_single_branch "https://github.com/qemu/qemu.git" "${BUILDDIR}/tmp/qemu" "$QEMU_RELEASE"
clone_single_branch "https://github.com/lyonel/lshw.git" "${BUILDDIR}/tmp/lshw" "$LSHW_RELEASE"
if $TINYIPA_REQUIRE_BIOSDEVNAME; then
    wget -N -O - https://linux.dell.com/biosdevname/biosdevname-${BIOSDEVNAME_RELEASE}/biosdevname-${BIOSDEVNAME_RELEASE}.tar.gz | tar -xz -C "${BUILDDIR}/tmp" -f -
fi
if $TINYIPA_REQUIRE_IPMITOOL; then
    wget -N -O - https://github.com/ipmitool/ipmitool/archive/IPMITOOL_${IPMITOOL_RELASE}.tar.gz | tar -xz -C "${BUILDDIR}/tmp" -f -
fi

# Create directory for python local mirror
mkdir -p "$BUILDDIR/tmp/localpip"

# Download IPA and requirements
IPA_SOURCE_DIR=${IPA_SOURCE_DIR:-/opt/stack/ironic-python-agent}
cd $IPA_SOURCE_DIR
rm -rf *.egg-info
pwd

PYTHON_COMMAND="python"
if [[ $USE_PYTHON3 == "True" ]]; then
    PYTHON_COMMAND="python3"
fi
$PYTHON_COMMAND setup.py sdist --dist-dir "$BUILDDIR/tmp/localpip" --quiet

ls $BUILDDIR/tmp/localpip || true
cp requirements.txt $BUILDDIR/tmp/ipa-requirements.txt

if [ -n "$IRONIC_LIB_SOURCE" ]; then
    pushd $IRONIC_LIB_SOURCE
    rm -rf *.egg-info
    $PYTHON_COMMAND setup.py sdist --dist-dir "$BUILDDIR/tmp/localpip" --quiet
    cp requirements.txt $BUILDDIR/tmp/ironic-lib-requirements.txt
    popd
fi

if [ -n "$PYTHON_EXTRA_SOURCES_DIR_LIST" ]; then
    IFS="," read -ra PKGDIRS <<< "$PYTHON_EXTRA_SOURCES_DIR_LIST"
    for PKGDIR in "${PKGDIRS[@]}"; do
        PKG=$(cd "$PKGDIR" ; $PYTHON_COMMAND setup.py --name)
        pushd "$PKGDIR"
        rm -rf *.egg-info
        $PYTHON_COMMAND setup.py sdist --dist-dir "$BUILDDIR/tmp/localpip" --quiet
        if [[ -r requirements.txt ]]; then
            cp requirements.txt $BUILDDIR/tmp/${PKG}-requirements.txt
        fi
        popd
    done
fi

$WORKDIR/generate_upper_constraints.sh upper-constraints.txt
if [ -n "$IRONIC_LIB_SOURCE" ]; then
    sed -i '/ironic-lib/d' upper-constraints.txt $BUILDDIR/tmp/ipa-requirements.txt
fi
cp upper-constraints.txt $BUILDDIR/tmp/upper-constraints.txt
echo Using upper-constraints:
cat upper-constraints.txt
cd $WORKDIR

sudo cp /etc/resolv.conf $BUILDDIR/etc/resolv.conf

trap "sudo umount $BUILDDIR/proc; sudo umount $BUILDDIR/dev/pts" EXIT
sudo mount --bind /proc $BUILDDIR/proc
sudo mount --bind /dev/pts $BUILDDIR/dev/pts

if [ -d /opt/stack/new ]; then
    CI_DIR=/opt/stack/new
elif [ -d /opt/stack ]; then
    CI_DIR=/opt/stack
else
    CI_DIR=
fi

if [ -n "$CI_DIR" ]; then
    # Running in CI environment, make checkouts available
    $CHROOT_CMD mkdir -p $CI_DIR
    for project in $(ls $CI_DIR); do
        if grep -q "$project" $BUILDDIR/tmp/upper-constraints.txt &&
            [ -d "$CI_DIR/$project/.git" ]; then
            sudo cp -R "$CI_DIR/$project" $BUILDDIR/$CI_DIR/
        fi
    done
fi

$CHROOT_CMD mkdir /etc/sysconfig/tcedir
$CHROOT_CMD chmod a+rwx /etc/sysconfig/tcedir
$CHROOT_CMD touch /etc/sysconfig/tcuser
$CHROOT_CMD chmod a+rwx /etc/sysconfig/tcuser

mkdir $BUILDDIR/tmp/overides
cp $WORKDIR/build_files/fakeuname $BUILDDIR/tmp/overides/uname

sudo cp $WORKDIR/build_files/ntpdate $BUILDDIR/bin/ntpdate

PY_REQS="buildreqs_python2.lst"
if [[ $USE_PYTHON3 == "True" ]]; then
    PY_REQS="buildreqs_python3.lst"
fi

# NOTE(rpittau) change ownership of the tce info dir to prevent writing issues
sudo chown $TC:$STAFF $BUILDDIR/usr/local/tce.installed

# NOTE(rpittau) patch tce-load to adapt to changes in squashfs module in
# latest kernel
sudo patch ${BUILDDIR}/usr/bin/tce-load < patches/tce-load_squashfs.patch

while read line; do
    sudo chroot --userspec=$TC:$STAFF $BUILDDIR /usr/bin/env -i PATH=$CHROOT_PATH http_proxy=$http_proxy https_proxy=$https_proxy no_proxy=$no_proxy tce-load -wci $line
done < <(paste $WORKDIR/build_files/$PY_REQS $WORKDIR/build_files/buildreqs.lst)

PIP_COMMAND="pip"
TINYIPA_PYTHON_EXE="python"
if [[ $USE_PYTHON3 == "True" ]]; then
    PIP_COMMAND="pip3"
    TINYIPA_PYTHON_EXE="python3"
fi

# Build python wheels
$CHROOT_CMD ${TINYIPA_PYTHON_EXE} -m ensurepip
$CHROOT_CMD ${PIP_COMMAND} install --upgrade pip wheel
$CHROOT_CMD ${PIP_COMMAND} install pbr
$CHROOT_CMD ${PIP_COMMAND} wheel -c /tmp/upper-constraints.txt --wheel-dir /tmp/wheels -r /tmp/ipa-requirements.txt
if [ -n "$IRONIC_LIB_SOURCE" ]; then
    $CHROOT_CMD ${PIP_COMMAND} wheel -c /tmp/upper-constraints.txt --wheel-dir /tmp/wheels -r /tmp/ironic-lib-requirements.txt
    $CHROOT_CMD ${PIP_COMMAND} wheel -c /tmp/upper-constraints.txt --no-index --pre --wheel-dir /tmp/wheels --find-links=/tmp/localpip --find-links=/tmp/wheels ironic-lib
fi

if [ -n "$PYTHON_EXTRA_SOURCES_DIR_LIST" ]; then
    IFS="," read -ra PKGDIRS <<< "$PYTHON_EXTRA_SOURCES_DIR_LIST"
    for PKGDIR in "${PKGDIRS[@]}"; do
        PKG=$(cd "$PKGDIR" ; $PYTHON_COMMAND setup.py --name)
        if [[ -r $BUILDDIR/tmp/${PKG}-requirements.txt ]]; then
            $CHROOT_CMD ${PIP_COMMAND} wheel -c /tmp/upper-constraints.txt --wheel-dir /tmp/wheels -r /tmp/${PKG}-requirements.txt
        fi
        $CHROOT_CMD ${PIP_COMMAND} wheel -c /tmp/upper-constraints.txt --no-index --pre --wheel-dir /tmp/wheels --find-links=/tmp/localpip --find-links=/tmp/wheels ${PKG}
    done
fi

$CHROOT_CMD ${PIP_COMMAND} wheel -c /tmp/upper-constraints.txt --no-index --pre --wheel-dir /tmp/wheels --find-links=/tmp/localpip --find-links=/tmp/wheels ironic-python-agent
echo Resulting wheels:
ls -1 $BUILDDIR/tmp/wheels

# Build tgt
rm -rf $WORKDIR/build_files/tgt.tcz
$CHROOT_CMD /bin/sh -c "cd /tmp/tgt && make && make install-programs install-conf install-scripts DESTDIR=/tmp/tgt-installed"
find $BUILDDIR/tmp/tgt-installed/ -type f -executable | xargs file | awk -F ':' '/ELF/ {print $1}' | sudo xargs strip
cd $WORKDIR/build_files && mksquashfs $BUILDDIR/tmp/tgt-installed tgt.tcz && md5sum tgt.tcz > tgt.tcz.md5.txt

# Build qemu-utils
rm -rf $WORKDIR/build_files/qemu-utils.tcz
$CHROOT_CMD /bin/sh -c "cd /tmp/qemu && ./configure --disable-system --disable-user --disable-linux-user --disable-bsd-user --disable-guest-agent --disable-blobs --python=/usr/local/bin/$TINYIPA_PYTHON_EXE && make && make install DESTDIR=/tmp/qemu-utils"
find $BUILDDIR/tmp/qemu-utils/ -type f -executable | xargs file | awk -F ':' '/ELF/ {print $1}' | sudo xargs strip
cd $WORKDIR/build_files && mksquashfs $BUILDDIR/tmp/qemu-utils qemu-utils.tcz && md5sum qemu-utils.tcz > qemu-utils.tcz.md5.txt
# Create qemu-utils.tcz.dep
echo "glib2.tcz" > qemu-utils.tcz.dep

# Build lshw
rm -rf $WORKDIR/build_files/lshw.tcz
# NOTE(mjturek): We touch src/lshw.1 and clear src/po/Makefile to avoid building the man pages, as they aren't used and require large dependencies to build.
$CHROOT_CMD /bin/sh -c "cd /tmp/lshw && touch src/lshw.1 && echo install: > src/po/Makefile && make && make install DESTDIR=/tmp/lshw-installed"
find $BUILDDIR/tmp/lshw-installed/ -type f -executable | xargs file | awk -F ':' '/ELF/ {print $1}' | sudo xargs strip
cd $WORKDIR/build_files && mksquashfs $BUILDDIR/tmp/lshw-installed lshw.tcz && md5sum lshw.tcz > lshw.tcz.md5.txt

# Build biosdevname
if $TINYIPA_REQUIRE_BIOSDEVNAME; then
    rm -rf $WORKDIR/build_files/biosdevname.tcz
    $CHROOT_CMD /bin/sh -c "cd /tmp/biosdevname-* && ./configure && make && make install DESTDIR=/tmp/biosdevname-installed"
    find $BUILDDIR/tmp/biosdevname-installed/ -type f -executable | xargs file | awk -F ':' '/ELF/ {print $1}' | sudo xargs strip
    cd $WORKDIR/build_files && mksquashfs $BUILDDIR/tmp/biosdevname-installed biosdevname.tcz && md5sum biosdevname.tcz > biosdevname.tcz.md5.txt
fi

if $TINYIPA_REQUIRE_IPMITOOL; then
    rm -rf $WORKDIR/build_files/ipmitool.tcz
    # NOTE(TheJulia): Explicitly add the libtool path since /usr/local/ is not in path from the chroot.
    $CHROOT_CMD /bin/sh -c "cd /tmp/ipmitool-* && env LIBTOOL='/usr/local/bin/libtool' ./bootstrap && ./configure && make && make install DESTDIR=/tmp/ipmitool"
    find $BUILDDIR/tmp/ipmitool/ -type f -executable | xargs file | awk -F ':' '/ELF/ {print $1}' | sudo xargs strip
    cd $WORKDIR/build_files && mksquashfs $BUILDDIR/tmp/ipmitool ipmitool.tcz && md5sum ipmitool.tcz > ipmitool.tcz.md5.txt
fi
