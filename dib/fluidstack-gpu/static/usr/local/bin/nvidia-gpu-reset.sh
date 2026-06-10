#!/bin/bash
# Reset all NVIDIA GPUs via PCIe FLR before the nvidia driver loads.
# This clears any leftover GSP/WPR2 state from a previous driver session
# (e.g. after kexec) that would cause RmInitAdapter to fail on boot.
set -eu

for dev in /sys/bus/pci/devices/*/; do
    vendor=$(cat "${dev}vendor" 2>/dev/null || true)
    [ "${vendor}" = "0x10de" ] || continue

    reset_method=$(cat "${dev}reset_method" 2>/dev/null || true)
    if echo "${reset_method}" | grep -q "flr"; then
        pci_id=$(basename "${dev}")
        echo "nvidia-gpu-reset: FLR on ${pci_id}"
        echo 1 > "${dev}reset"
    fi
done
