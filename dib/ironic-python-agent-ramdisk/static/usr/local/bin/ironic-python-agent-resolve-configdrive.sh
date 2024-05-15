#!/bin/bash

set -eux
set -o pipefail

echo "Resolving the configuration drive for Ironic."

PATH=/bin:/usr/bin:/sbin:/usr/sbin

# Inspired by/based on glean-early.sh
# https://opendev.org/opendev/glean/src/branch/master/glean/init/glean-early.sh

# NOTE(TheJulia): We care about iso images, and would expect lower case as a
# result. In the case of VFAT partitions, they would be upper case.
CONFIG_DRIVE_LABEL="config-2"

# Identify the number of devices
device_count=$(lsblk -o PATH,LABEL | grep $CONFIG_DRIVE_LABEL | wc -l)

# Identify if we have an a publisher id set
publisher_id=""
if grep -q "ir_pub_id" /proc/cmdline; then
    publisher_id=$(cat /proc/cmdline | sed -e 's/^.*ir_pub_id=//' -e 's/ .*$//')
fi

if [ $device_count -lt 1 ]; then
    # Nothing to do here, exit!
    exit 0
else
    # We have *something* to do here.
    mkdir -p /mnt/config
    if [[ "${publisher_id}" != "" ]]; then
        # We need to enumerate through the devices, and obtain the
        for device in $(lsblk -o PATH,LABEL|grep config-2|cut -f1 -d" "); do
            device_id=$(udevadm info --query=property --property=ID_FS_PUBLISHER_ID $device | sed s/ID_FS_PUBLISHER_ID=//)
            if [[ "${publisher_id}" == "${device_id}" ]]; then
                # SUCCESS! Valid device! Do it!
                echo "Device ${device} matches the ${publisher_id}. Mounting..."
                mount -t iso9660 -o ro,mode=0700 "${device}" /mnt/config || true
                # We've mounted the device, the world is happy.
                exit 0
            else
                echo "Did not identify $device as a valid ISO for Ironic."
            fi
        done
    fi
fi
