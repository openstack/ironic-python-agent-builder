#!/bin/bash

# Rebuild upstream pre-built tinyipa it to be usable with ansible-deploy.
#
# Downloads the pre-built tinyipa ramdisk from tarballs.openstack.org or
# rebuilds a ramdisk under path set as TINYIPA_RAMDISK_FILE shell var.

# During rebuild this script installs and configures OpenSSH server if needed
# and makes required changes for Ansible + Python to work in compiled/optimized
# Python environment.
#
# By default, id_rsa or id_dsa keys  of the user performing the build
# are baked into the image as authorized_keys for 'tc' user.
# To supply different public ssh key, before running this script set
# SSH_PUBLIC_KEY environment variable to point to absolute path to the key.
#
# This script produces "ansible-<tinyipa-ramdisk-name>" ramdisk that can serve
# as ramdisk for both ansible-deploy driver and agent-based Ironic drivers,

set -ex
WORKDIR=$(readlink -f $0 | xargs dirname)
REBUILDDIR="$WORKDIR/tinyipaaddssh"
DST_DIR=$REBUILDDIR
source ${WORKDIR}/common.sh

TINYCORE_MIRROR_URL=${TINYCORE_MIRROR_URL:-}
BRANCH_PATH=${BRANCH_PATH:-master}
TINYIPA_RAMDISK_FILE=${TINYIPA_RAMDISK_FILE:-}

SSH_PUBLIC_KEY=${SSH_PUBLIC_KEY:-}

SSHD_CONFIG_PATH="/usr/local/etc/ssh/sshd_config"
SSH_RSA_KEY_PATH="/usr/local/etc/ssh/ssh_host_rsa_key"
SSH_DSA_KEY_PATH="/usr/local/etc/ssh/ssh_host_dsa_key"
SSH_ED25519_KEY_PATH="/usr/local/etc/ssh/ssh_host_ed25519_key"

function validate_params {
    echo "Validating location of public SSH key"
    if [ -n "$SSH_PUBLIC_KEY" ]; then
        if [ -r "$SSH_PUBLIC_KEY" ]; then
            _found_ssh_key="$SSH_PUBLIC_KEY"
        fi
    else
        for fmt in rsa dsa; do
            if [ -r "$HOME/.ssh/id_$fmt.pub" ]; then
                _found_ssh_key="$HOME/.ssh/id_$fmt.pub"
                break
            fi
        done
    fi

    if [ -z $_found_ssh_key ]; then
        echo "Failed to find neither provided nor default SSH key"
        exit 1
    fi
}

function get_tinyipa {
    if [ -z $TINYIPA_RAMDISK_FILE ]; then
        mkdir -p $WORKDIR/build_files/cache
        cd $WORKDIR/build_files/cache
        wget -N https://tarballs.openstack.org/ironic-python-agent/tinyipa/files/tinyipa${BRANCH_EXT}.gz
        TINYIPA_RAMDISK_FILE="$WORKDIR/build_files/cache/tinyipa${BRANCH_EXT}.gz"
    fi
}

function unpack_ramdisk {

    if [ -d "$REBUILDDIR" ]; then
        sudo rm -rf "$REBUILDDIR"
    fi

    mkdir -p "$REBUILDDIR"

    # Extract rootfs from .gz file
    ( cd "$REBUILDDIR" && zcat "$TINYIPA_RAMDISK_FILE" | sudo cpio -i -H newc -d )

}

function install_ssh {
    if [ ! -f "${REBUILDDIR}${SSHD_CONFIG_PATH}" ]; then
        # tinyipa was built without SSH server installed
        # Install and configure bare minimum for SSH access
        $TC_CHROOT_CMD tce-load -wic openssh
        # Configure OpenSSH
        $CHROOT_CMD cp ${SSHD_CONFIG_PATH}.orig $SSHD_CONFIG_PATH
        echo "PasswordAuthentication no" | $CHROOT_CMD tee -a $SSHD_CONFIG_PATH
        # Generate and configure host keys - RSA, DSA, Ed25519
        # NOTE(pas-ha) ECDSA host key will still be re-generated fresh on every image boot
        $CHROOT_CMD ssh-keygen -q -t rsa -N "" -f $SSH_RSA_KEY_PATH
        $CHROOT_CMD ssh-keygen -q -t dsa -N "" -f $SSH_DSA_KEY_PATH
        $CHROOT_CMD ssh-keygen -q -t ed25519 -N "" -f $SSH_ED25519_KEY_PATH
        echo "HostKey ${SSH_RSA_KEY_PATH}" | $CHROOT_CMD tee -a $SSHD_CONFIG_PATH
        echo "HostKey ${SSH_DSA_KEY_PATH}" | $CHROOT_CMD tee -a $SSHD_CONFIG_PATH
        echo "HostKey ${SSH_ED25519_KEY_PATH}" | $CHROOT_CMD tee -a $SSHD_CONFIG_PATH
    fi

    # setup new user SSH keys anyway
    $CHROOT_CMD mkdir -p /home/tc
    $CHROOT_CMD chown -R tc.staff /home/tc
    $TC_CHROOT_CMD mkdir -p /home/tc/.ssh
    cat $_found_ssh_key | $TC_CHROOT_CMD tee /home/tc/.ssh/authorized_keys
    $CHROOT_CMD chown tc.staff /home/tc/.ssh/authorized_keys
    $TC_CHROOT_CMD chmod 600 /home/tc/.ssh/authorized_keys
}


function rebuild_ramdisk {
    # Rebuild build directory into gz file
    ansible_basename="ansible-$(basename $TINYIPA_RAMDISK_FILE)"
    ( cd "$REBUILDDIR" && sudo find | sudo cpio -o -H newc | gzip -9 > "$WORKDIR/${ansible_basename}" )
    # Output file created by this script and its size
    cd "$WORKDIR"
    echo "Produced files:"
    du -h "${ansible_basename}"
}

sudo -v


validate_params
get_tinyipa
unpack_ramdisk
setup_tce "$DST_DIR"

# NOTE (pas-ha) default tinyipa is built without SSH access, enable it here
install_ssh

cleanup_tce "$DST_DIR"
rebuild_ramdisk
