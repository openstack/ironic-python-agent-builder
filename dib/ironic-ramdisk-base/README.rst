ironic-ramdisk-base
===================

This is a base element for ironic ramdisks. It does not install anything, just
takes the prepared images and extract kernel/ramdisk from it.

Configurable Environment Variables
----------------------------------
- `DIB_IPA_COMPRESS_COMMAND` defaults to `gzip`, may be set to any valid
  compression program usable for an initramfs
- `DIB_IPA_MINIMAL_PRUNE` defaults to `0` (false). If set to `1`, will skip
  most ramdisk size optimizations. This may be helpful for use of packages
  with IPA that require otherwise-pruned directories or files.

