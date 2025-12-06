#!/bin/bash

set -eux
set -o pipefail

echo "Resolving the configuration drive for Ironic."

PATH=/bin:/usr/bin:/sbin:/usr/sbin

# Inspired by/based on glean-early.sh
# https://opendev.org/opendev/glean/src/branch/master/glean/init/glean-early.sh

# Identify if we have an a publisher id set
publisher_id=""
if grep -q "ir_pub_id" /proc/cmdline; then
    publisher_id=$(cat /proc/cmdline | sed -e 's/^.*ir_pub_id=//' -e 's/ .*$//')
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
