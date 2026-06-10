#!/bin/bash
# ironwood-auto-kexec: if the Ironic node is in 'active' state (provisioned),
# kexec directly into the installed OS instead of letting IPA run normally.
# This makes Ironwood TPU machines boot into their installed OS on every
# reboot without requiring LinuxBoot's Verified Disk Boot.
set -e

log() { echo "ironwood-auto-kexec: $*" >&2; }

# Get Ironic API URL from kernel cmdline
IPA_API_URL=$(grep -oP 'ipa-api-url=\K\S+' /proc/cmdline 2>/dev/null || true)
if [ -z "$IPA_API_URL" ]; then
    log "no ipa-api-url in cmdline, exiting"
    exit 0
fi

# Wait up to 120s for the route to the Ironic API to be available.
# The BMC USB NIC gets a global address early but has no route to Ironic.
# The DCN interfaces (ens8f0/ens40f0) must be up with DHCPv6 addresses first.
log "waiting for route to Ironic..."
# Extract IPv6 address from bracketed URL form: http://[addr]:port
IRONIC_HOST=$(echo "$IPA_API_URL" | grep -oP '(?<=\[)[0-9a-f:]+(?=\])' | head -1)
# Fallback for IPv4 or bare hostname
[ -z "$IRONIC_HOST" ] && IRONIC_HOST=$(echo "$IPA_API_URL" | grep -oP '(?<=://)[^/:]+' | head -1)
[ -z "$IRONIC_HOST" ] && IRONIC_HOST="fc00:ffff:ffff:f158::6385:1"
for i in $(seq 1 150); do
    if ip -6 route get "${IRONIC_HOST}" 2>/dev/null | grep -q "via"; then
        log "route to Ironic available (attempt $i)"
        break
    fi
    sleep 2
done

if ! ip -6 route get "${IRONIC_HOST}" 2>/dev/null | grep -q "via"; then
    log "no route to Ironic after 300s, exiting"
    exit 0
fi

# Use the boot NIC MAC to find the node via the ports API.
# /v1/lookup only works for nodes expecting an active agent (not 'active' nodes).
BOOT_MAC=$(cat /sys/class/net/ens8f0/address 2>/dev/null || \
           cat /sys/class/net/ens40f0/address 2>/dev/null)
if [ -z "$BOOT_MAC" ]; then
    log "could not determine boot MAC, exiting"
    exit 0
fi

log "finding node in Ironic via MAC ${BOOT_MAC}"
NODE_UUID=$(curl -s --max-time 10 \
    -H "X-OpenStack-Ironic-API-Version: 1.109" \
    "${IPA_API_URL}/v1/ports?address=${BOOT_MAC}&fields=node_uuid" 2>/dev/null | \
    python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    ports = d.get('ports', [])
    print(ports[0]['node_uuid'] if ports else '')
except:
    print('')
" 2>/dev/null)

if [ -z "$NODE_UUID" ]; then
    log "no node found for MAC ${BOOT_MAC}, exiting"
    exit 0
fi

log "found node ${NODE_UUID}, waiting for active state (up to 120s)..."
NODE_STATE=""
for i in $(seq 1 24); do
    NODE_STATE=$(curl -s --max-time 10 \
        -H "X-OpenStack-Ironic-API-Version: 1.109" \
        "${IPA_API_URL}/v1/nodes/${NODE_UUID}?fields=provision_state" 2>/dev/null | \
        python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('provision_state', ''))
except:
    print('')
" 2>/dev/null)
    log "node provision_state: '${NODE_STATE}' (attempt ${i})"
    [ "$NODE_STATE" = "active" ] && break
    sleep 5
done

if [ "$NODE_STATE" != "active" ]; then
    log "node not active after waiting, staying in IPA"
    exit 0
fi

log "node is active — kexec-ing into installed OS"

ROOT_DEV=$(blkid -L cloudimg-rootfs 2>/dev/null | head -1)
if [ -z "$ROOT_DEV" ]; then
    log "could not find root partition (cloudimg-rootfs label), staying in IPA"
    exit 0
fi
ROOT_UUID=$(blkid "$ROOT_DEV" -s UUID -o value 2>/dev/null)
if [ -z "$ROOT_UUID" ]; then
    log "could not read UUID of $ROOT_DEV, staying in IPA"
    exit 0
fi

# Support two partition layouts:
#   1. Separate BOOT-labelled partition (original Ubuntu cloud image)
#   2. /boot/ inside root partition (DIB-built ironwood image)
BOOT_MOUNT=/tmp/ironwood-boot
mkdir -p "$BOOT_MOUNT"

BOOT_DEV=$(blkid -L BOOT 2>/dev/null | head -1)
if [ -n "$BOOT_DEV" ]; then
    log "found BOOT partition: $BOOT_DEV"
    mount "$BOOT_DEV" "$BOOT_MOUNT" || { log "mount failed, staying in IPA"; exit 0; }
    KERNEL_DIR="$BOOT_MOUNT"
else
    log "no BOOT partition, mounting root $ROOT_DEV and looking in /boot/"
    mount "$ROOT_DEV" "$BOOT_MOUNT" || { log "root mount failed, staying in IPA"; exit 0; }
    KERNEL_DIR="${BOOT_MOUNT}/boot"
fi

KERNEL=$(ls "${KERNEL_DIR}"/vmlinuz-* 2>/dev/null | sort -V | tail -1)
INITRD=$(ls "${KERNEL_DIR}"/initrd.img-* 2>/dev/null | sort -V | tail -1)

if [ -z "$KERNEL" ] || [ -z "$INITRD" ]; then
    umount "$BOOT_MOUNT" 2>/dev/null
    log "no kernel/initrd found in ${KERNEL_DIR}, staying in IPA"
    exit 0
fi

log "loading kernel: $(basename "$KERNEL")"
kexec -l "$KERNEL" \
    --initrd="$INITRD" \
    --command-line="root=UUID=${ROOT_UUID} ro fsck.mode=force fsck.repair=yes transparent_hugepage=always console=tty1 console=ttyS0,115200"

umount "$BOOT_MOUNT" 2>/dev/null

log "executing kexec — jumping into Ubuntu"
kexec -e

# kexec -e only returns on failure
log "kexec -e returned unexpectedly, staying in IPA"
exit 1
