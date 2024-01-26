#!/bin/bash

set -ex
WORKDIR=$(readlink -f $0 | xargs dirname)
FINALDIR="$WORKDIR/tinyipafinal"
DST_DIR=$FINALDIR
source ${WORKDIR}/common.sh

BUILD_AND_INSTALL_TINYIPA=${BUILD_AND_INSTALL_TINYIPA:-true}
INSTALL_SSH=${INSTALL_SSH:-true}
AUTHORIZE_SSH=${AUTHORIZE_SSH:-false}

SSH_PUBLIC_KEY=${SSH_PUBLIC_KEY:-}
PYOPTIMIZE_TINYIPA=${PYOPTIMIZE_TINYIPA:-false}
TINYIPA_UDEV_SETTLE_TIMEOUT=${TINYIPA_UDEV_SETTLE_TIMEOUT:-60}

echo "Finalising tinyipa:"

if [ -n "$PYTHON_EXTRA_SOURCES_DIR_LIST" ]; then
    IFS="," read -ra PKGDIRS <<< "$PYTHON_EXTRA_SOURCES_DIR_LIST"
    for PKGDIR in "${PKGDIRS[@]}"; do
        PKG=$(cd "$PKGDIR" ; python setup.py --name)
    done
fi

if $AUTHORIZE_SSH ; then
    echo "Validating location of public SSH key"
    if [ -n "$SSH_PUBLIC_KEY" ]; then
        if [ -f "$SSH_PUBLIC_KEY" ]; then
            _found_ssh_key="$SSH_PUBLIC_KEY"
        fi
    else
        for fmt in rsa dsa; do
            if [ -f "$HOME/.ssh/id_$fmt.pub" ]; then
                _found_ssh_key="$HOME/.ssh/id_$fmt.pub"
                break
            fi
        done
    fi

    if [ -z $_found_ssh_key ]; then
        echo "Failed to find neither provided nor default SSH key"
        exit 1
    fi
fi

sudo -v

# Let's umount proc in case the old finalise process went sideways and
# it's still mounted
if grep -qs "$FINALDIR/proc" /proc/mounts; then
    sudo umount "$FINALDIR/proc"
fi

# Remove the old final chroot dir with all its content before starting a new
# finalise process
if [ -d "$FINALDIR" ]; then
    sudo rm -rf "$FINALDIR"
fi

mkdir "$FINALDIR"

# Extract rootfs from .gz file
( cd "$FINALDIR" && zcat $WORKDIR/build_files/corepure64.gz | sudo cpio -i -H newc -d )

# Setup Final Dir
setup_tce "$DST_DIR"

# Modify ldconfig for x86-64
$CHROOT_CMD cp /sbin/ldconfig /sbin/ldconfigold
printf '#!/bin/sh\n/sbin/ldconfigold $@ | sed -r "s/libc6|ELF/libc6,x86-64/"' | $CHROOT_CMD tee -a /sbin/ldconfignew
$CHROOT_CMD cp /sbin/ldconfignew /sbin/ldconfig
$CHROOT_CMD chmod u+x /sbin/ldconfig

# Copy python wheels from build to final dir
cp -Rp "$BUILDDIR/tmp/wheels" "$FINALDIR/tmp/wheelhouse"

cp $WORKDIR/build_files/qemu-utils.* $FINALDIR/tmp/builtin/optional
cp $WORKDIR/build_files/lshw.* $FINALDIR/tmp/builtin/optional

if $TINYIPA_REQUIRE_BIOSDEVNAME; then
    cp $WORKDIR/build_files/biosdevname.* $FINALDIR/tmp/builtin/optional
fi
if $TINYIPA_REQUIRE_IPMITOOL; then
    cp $WORKDIR/build_files/ipmitool.* $FINALDIR/tmp/builtin/optional
fi

mkdir $FINALDIR/tmp/overrides
cp $WORKDIR/build_files/fakeuname $FINALDIR/tmp/overrides/uname

sudo cp $WORKDIR/build_files/ntpdate $FINALDIR/bin/ntpdate
sudo chmod 755 $FINALDIR/bin/ntpdate
PY_REQS="finalreqs_python3.lst"

# NOTE(rpittau) change ownership of the tce info dir to prevent writing issues
sudo chown $TC:$STAFF $FINALDIR/usr/local/tce.installed

while read line; do
    $TC_CHROOT_CMD tce-load -wic $line
done < <(paste $WORKDIR/build_files/finalreqs.lst $WORKDIR/build_files/$PY_REQS)

if $INSTALL_SSH ; then
    # Install and configure bare minimum for SSH access
    $TC_CHROOT_CMD tce-load -wic openssh
    # Configure OpenSSH
    $CHROOT_CMD cp /usr/local/etc/ssh/sshd_config.orig /usr/local/etc/ssh/sshd_config
    echo "PasswordAuthentication no" | $CHROOT_CMD tee -a /usr/local/etc/ssh/sshd_config
    # Generate and configure host keys - RSA, DSA, Ed25519
    # NOTE(pas-ha) ECDSA host key will still be re-generated fresh on every image boot
    $CHROOT_CMD ssh-keygen -t rsa -N "" -f /usr/local/etc/ssh/ssh_host_rsa_key
    $CHROOT_CMD ssh-keygen -t dsa -N "" -f /usr/local/etc/ssh/ssh_host_dsa_key
    $CHROOT_CMD ssh-keygen -t ed25519 -N "" -f /usr/local/etc/ssh/ssh_host_ed25519_key
    echo "HostKey /usr/local/etc/ssh/ssh_host_rsa_key" | $CHROOT_CMD tee -a /usr/local/etc/ssh/sshd_config
    echo "HostKey /usr/local/etc/ssh/ssh_host_dsa_key" | $CHROOT_CMD tee -a /usr/local/etc/ssh/sshd_config
    echo "HostKey /usr/local/etc/ssh/ssh_host_ed25519_key" | $CHROOT_CMD tee -a /usr/local/etc/ssh/sshd_config

    # setup user and SSH keys
    if $AUTHORIZE_SSH; then
        $CHROOT_CMD mkdir -p /home/tc
        $CHROOT_CMD chown -R tc.staff /home/tc
        $TC_CHROOT_CMD mkdir -p /home/tc/.ssh
        cat $_found_ssh_key | $TC_CHROOT_CMD tee /home/tc/.ssh/authorized_keys
        $CHROOT_CMD chown tc.staff /home/tc/.ssh/authorized_keys
        $TC_CHROOT_CMD chmod 600 /home/tc/.ssh/authorized_keys
    fi
fi

$TC_CHROOT_CMD tce-load -ic /tmp/builtin/optional/qemu-utils.tcz
$TC_CHROOT_CMD tce-load -ic /tmp/builtin/optional/lshw.tcz
if $TINYIPA_REQUIRE_BIOSDEVNAME; then
    $TC_CHROOT_CMD tce-load -ic /tmp/builtin/optional/biosdevname.tcz
fi
if $TINYIPA_REQUIRE_IPMITOOL; then
    $TC_CHROOT_CMD tce-load -ic /tmp/builtin/optional/ipmitool.tcz
fi

# Ensure tinyipa picks up installed kernel modules
$CHROOT_CMD depmod -a `$WORKDIR/build_files/fakeuname -r`

PIP_COMMAND="pip3"
TINYIPA_PYTHON_EXE="python3"

# Install pip
# NOTE(rpittau): pip MUST be the same version used in the build script or
# dragons will appear and put everything on fire
$CHROOT_CMD ${TINYIPA_PYTHON_EXE} -m ensurepip
$CHROOT_CMD ${PIP_COMMAND} install --upgrade pip==${PIP_VERSION} wheel

# If flag is set install python now
if $BUILD_AND_INSTALL_TINYIPA ; then
    if [ -n "$PYTHON_EXTRA_SOURCES_DIR_LIST" ]; then
        IFS="," read -ra PKGDIRS <<< "$PYTHON_EXTRA_SOURCES_DIR_LIST"
        for PKGDIR in "${PKGDIRS[@]}"; do
            PKG=$(cd "$PKGDIR" ; python setup.py --name)
            $CHROOT_CMD $PIP_COMMAND install --no-index --find-links=file:///tmp/wheelhouse --pre $PKG
        done
    fi

    $CHROOT_CMD $PIP_COMMAND install --no-index --find-links=file:///tmp/wheelhouse --pre ironic_python_agent

    rm -rf $FINALDIR/tmp/wheelhouse
fi

# Unmount /proc and clean up everything
cleanup_tce "$DST_DIR"

# Copy bootlocal.sh to opt
sudo cp "$WORKDIR/build_files/bootlocal.sh" "$FINALDIR/opt/."

# Copy udhcpc.script to opt
sudo cp "$WORKDIR/udhcpc.script" "$FINALDIR/opt/"

# Replace etc/init.d/dhcp.sh
sudo cp "$WORKDIR/build_files/dhcp.sh" "$FINALDIR/etc/init.d/dhcp.sh"
sudo sed -i "s/%UDEV_SETTLE_TIMEOUT%/$TINYIPA_UDEV_SETTLE_TIMEOUT/" "$FINALDIR/etc/init.d/dhcp.sh"

# Disable ZSwap
sudo sed -i '/# Main/a NOZSWAP=1' "$FINALDIR/etc/init.d/tc-config"
# sudo cp $WORKDIR/build_files/tc-config $FINALDIR/etc/init.d/tc-config

# Place ipv6 modprobe config so the kernel support loads.
sudo cp "$WORKDIR/build_files/modprobe.conf" "$FINALDIR/etc/modproble.conf"

# NOTE(rpittau): workaround for hwclock
# The adjtime file used by hwclock in tinycore is /var/lib/hwclock/adjtime
# but for some reason (bug?) the file is not created when hwclock is
# invoked, causing hwclock to fail when using certain options, for example
# --systohc.
# We create the dir and the file to prevent that.
$CHROOT_CMD mkdir -p /var/lib/hwclock
$CHROOT_CMD touch /var/lib/hwclock/adjtime
$CHROOT_CMD chmod 640 /var/lib/hwclock/adjtime

if $PYOPTIMIZE_TINYIPA; then
    echo "WARNING: Precompilation is not compatible with oslo.privsep and is being ignored."
fi

# Delete unnecessary Babel .dat files
find $FINALDIR -path "*babel/locale-data/*.dat" -not -path "*en_US*" | sudo xargs --no-run-if-empty rm

# NOTE(pas-ha) Apparently on TinyCore Ansible's 'command' module is
# not searching for executables in the '/usr/local/(s)bin' paths.
# Thus we symlink everything from there to '/usr/(s)bin' which is being searched,
# so that 'command' module picks full utilities installed by 'util-linux'
# instead of built-in simplified BusyBox ones.
set +x
echo "Symlink all from /usr/local/sbin to /usr/sbin"
pushd "$FINALDIR/usr/local/sbin"
for target in *; do
    if [ ! -f "$FINALDIR/usr/sbin/$target" ]; then
        $CHROOT_CMD ln -sf "/usr/local/sbin/$target" "/usr/sbin/$target"
    fi
done
popd
echo "Symlink all from /usr/local/bin to /usr/bin"
# this also includes symlinking Python to the place expected by Ansible
pushd "$FINALDIR/usr/local/bin"
for target in *; do
    if [ ! -f "$FINALDIR/usr/bin/$target" ]; then
        $CHROOT_CMD ln -sf "/usr/local/bin/$target" "/usr/bin/$target"
    fi
done
popd
# symlink bash to sh if /bin/sh is not there
if [ ! -f "$FINALDIR/bin/sh" ]; then
    $CHROOT_CMD ln -sf "/bin/bash" "/bin/sh"
fi
set -x

# Rebuild build directory into gz file
( cd "$FINALDIR" && sudo find | sudo cpio -o -H newc | gzip -9 > "$WORKDIR/tinyipa${BRANCH_EXT}.gz" )

# Copy vmlinuz to new name
cp "$WORKDIR/build_files/vmlinuz64" "$WORKDIR/tinyipa${BRANCH_EXT}.vmlinuz"

# Create tar.gz containing tinyipa files
tar czf tinyipa${BRANCH_EXT}.tar.gz tinyipa${BRANCH_EXT}.gz tinyipa${BRANCH_EXT}.vmlinuz

# Create sha256 files which will be uploaded by the publish jobs along with
# the tinyipa ones in order to provide a way to verify the integrity of the tinyipa
# builds.
for f in tinyipa${BRANCH_EXT}.{gz,tar.gz,vmlinuz}; do
    sha256sum $f > $f.sha256
done

# Output files with sizes created by this script
echo "Produced files:"
du -h tinyipa${BRANCH_EXT}.gz tinyipa${BRANCH_EXT}.tar.gz tinyipa${BRANCH_EXT}.vmlinuz
echo "Checksums: " tinyipa${BRANCH_EXT}.*sha256
