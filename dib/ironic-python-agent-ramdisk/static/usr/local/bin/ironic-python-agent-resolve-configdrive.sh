#!/bin/bash

set -eux
set -o pipefail

echo "Resolving the configuration drive for Ironic."

PATH=/bin:/usr/bin:/sbin:/usr/sbin

# Inspired by/based on glean-early.sh
# https://opendev.org/opendev/glean/src/branch/master/glean/init/glean-early.sh
#
# What this script does, given we have disabled glean-early from executing,
# it mounts the configuration drive contents *if* appropriate. Otherwise
# everything falls into the default dhcp/address discovery path.

# Identify if we have an a publisher id set
publisher_id=""
if grep -q "ir_pub_id" /proc/cmdline; then
    publisher_id=$(cat /proc/cmdline | sed -e 's/^.*ir_pub_id=//' -e 's/ .*$//')
fi

if grep -q "BOOTIF" /proc/cmdline; then
    # This is clearly a network boot or agent boot operation, which means
    # we should double check if we have a publisher_id from Ironic.
    if [[ "${publisher_id,,}" == "" ]]; then
        # No publisher ID is present on the command line, Stop here.
        # No need to proceed.
        echo "Non-vmedia based deploy detected - skipping configuration."
        exit 1
    fi
fi

# NOTE(TheJulia): We care about iso images, and would expect lower case as a
# result. In the case of VFAT partitions, they would be upper case.
CONFIG_DRIVE_LABEL="config-2"

i=0
while [ $i -lt 30 ] ; do
    i=$((i + 1))

    for device in $(lsblk -o PATH,LABEL | grep "$CONFIG_DRIVE_LABEL" | cut -d" " -f1); do
        device_id=$(udevadm info --query=property --property=ID_FS_PUBLISHER_ID "$device" | sed s/ID_FS_PUBLISHER_ID=//)
        if [[ "${publisher_id,,}" == "${device_id,,}" ]]; then
            # SUCCESS! Valid device! Mount it!
            echo "Device ${device} matches publisher id ${publisher_id}. Mounting..."
            mkdir -p /mnt/config
            mount -t iso9660 -o ro,mode=0700 "${device}" /mnt/config || true
            # We've mounted the device, the world is happy.
            exit 0
        fi
    done

    sleep 1
done

# No device found
echo "No valid configuration drive found for Ironic."
lsblk -o PATH,LABEL
exit 1
