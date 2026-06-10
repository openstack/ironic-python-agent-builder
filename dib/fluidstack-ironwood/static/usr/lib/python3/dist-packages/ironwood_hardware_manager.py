"""
Ironwood TPU hardware manager for Ironic Python Agent.

Adds a kexec_boot deploy step that jumps directly into the installed OS
after image deployment, bypassing LinuxBoot's Verified Disk Boot which
requires LUKS encryption and EEPROM unlock on Ironwood TPU machines.
"""

import logging
import os
import subprocess

from ironic_python_agent import errors
from ironic_python_agent import hardware

LOG = logging.getLogger(__name__)

# Boot partition label used by Ubuntu cloud images
_BOOT_LABEL = 'BOOT'
_BOOT_MOUNT = '/tmp/ironwood-boot'


def _find_boot_partition():
    """Find the partition with BOOT label."""
    try:
        result = subprocess.run(
            ['blkid', '-L', _BOOT_LABEL],
            capture_output=True, text=True, timeout=10)
        dev = result.stdout.strip()
        if dev:
            return dev
    except Exception:
        pass

    # Fallback: scan nvme partitions for ext4 with boot files
    for part in ['/dev/nvme0n1p16', '/dev/nvme0n1p2', '/dev/nvme0n1p1']:
        if os.path.exists(part):
            result = subprocess.run(
                ['blkid', part, '-s', 'TYPE', '-o', 'value'],
                capture_output=True, text=True, timeout=5)
            if result.stdout.strip() == 'ext4':
                return part
    return None


def _find_root_uuid():
    """Find the root partition UUID (cloudimg-rootfs label)."""
    result = subprocess.run(
        ['blkid', '-L', 'cloudimg-rootfs'],
        capture_output=True, text=True, timeout=10)
    dev = result.stdout.strip()
    if dev:
        result = subprocess.run(
            ['blkid', dev, '-s', 'UUID', '-o', 'value'],
            capture_output=True, text=True, timeout=5)
        return result.stdout.strip()
    return None


class IronwoodHardwareManager(hardware.GenericHardwareManager):
    """Hardware manager for Google Ironwood TPU machines."""

    HARDWARE_MANAGER_NAME = 'IronwoodHardwareManager'
    HARDWARE_MANAGER_VERSION = '1'

    def evaluate_hardware_support(self):
        """Only activate on Ironwood (Quanta/Google) hardware."""
        try:
            with open('/sys/class/dmi/id/board_vendor', 'r') as f:
                vendor = f.read().strip().lower()
            if 'quanta' in vendor or 'google' in vendor:
                return hardware.HardwareSupport.SERVICE_PROVIDER
        except Exception:
            pass
        # Also check product name for izumi (Ironwood code name)
        try:
            with open('/sys/class/dmi/id/product_name', 'r') as f:
                product = f.read().strip().lower()
            if 'izumi' in product or 'ironwood' in product:
                return hardware.HardwareSupport.SERVICE_PROVIDER
        except Exception:
            pass
        return hardware.HardwareSupport.NONE

    def get_deploy_steps(self, node, ports):
        """Return Ironwood-specific deploy steps.

        kexec is handled by ironwood-auto-kexec.service on the next boot
        once the node reaches active state, avoiding the race where kexec
        kills IPA before Ironic polls for the step result.
        """
        return []

    def kexec_boot(self, node, ports):
        """kexec into the installed OS, bypassing LinuxBoot Verified Disk Boot.

        After write_image and install_bootloader complete, this step loads
        the installed kernel via kexec and immediately jumps into it without
        going through firmware. This works around the Ironwood LinuxBoot
        requirement for LUKS-encrypted partitions with EEPROM unlock.
        """
        LOG.info('Starting kexec_boot deploy step for Ironwood TPU')

        boot_part = _find_boot_partition()
        if not boot_part:
            raise errors.DeploymentError(
                'kexec_boot: could not find boot partition (BOOT label)')

        LOG.info('Found boot partition: %s', boot_part)

        os.makedirs(_BOOT_MOUNT, exist_ok=True)
        subprocess.run(['mount', boot_part, _BOOT_MOUNT],
                       check=True, timeout=30)

        try:
            # Find latest kernel and initrd
            kernels = sorted([
                f for f in os.listdir(_BOOT_MOUNT)
                if f.startswith('vmlinuz-')
            ])
            initrds = sorted([
                f for f in os.listdir(_BOOT_MOUNT)
                if f.startswith('initrd.img-')
            ])

            if not kernels or not initrds:
                raise errors.DeploymentError(
                    'kexec_boot: no kernel/initrd found on boot partition')

            kernel = os.path.join(_BOOT_MOUNT, kernels[-1])
            initrd = os.path.join(_BOOT_MOUNT, initrds[-1])
            LOG.info('Using kernel: %s, initrd: %s', kernel, initrd)

            root_uuid = _find_root_uuid()
            if not root_uuid:
                raise errors.DeploymentError(
                    'kexec_boot: could not find root partition UUID')

            LOG.info('Root UUID: %s', root_uuid)

            cmdline = (
                'root=UUID={uuid} ro '
                'fsck.mode=force fsck.repair=yes '
                'transparent_hugepage=always '
                'console=tty1 console=ttyS0,115200'
            ).format(uuid=root_uuid)

            # Load the kernel
            subprocess.run(
                ['kexec', '-l', kernel,
                 '--initrd={}'.format(initrd),
                 '--command-line={}'.format(cmdline)],
                check=True, timeout=30)

            LOG.info('kexec loaded into memory')

        finally:
            subprocess.run(['umount', _BOOT_MOUNT],
                           timeout=10, check=False)

        # Schedule kexec in an independent process so IPA can return success
        # to Ironic before the kernel is replaced. Without this, kexec kills
        # IPA before Ironic receives the step result, causing deploy failed.
        subprocess.Popen(
            ['/bin/sh', '-c', 'sleep 8 && exec kexec -e'],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
            close_fds=True,
        )
        LOG.info('kexec scheduled in 8s — returning success to Ironic now')
