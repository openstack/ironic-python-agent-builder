===========================
ironic-python-agent-ramdisk
===========================
Builds a ramdisk with ironic-python-agent.

More information can be found at:
https://docs.openstack.org/ironic-python-agent/latest/

This element extends the minimal element ``ironic-python-agent-ramdisk-base``
with the following:

* Installs the ``dhcp-all-interfaces`` so the node, upon booting, attempts to
  obtain an IP address on all available network interfaces.
* Installs ``podman`` package to support deploying bootc images

This element outputs three files:

- ``$IMAGE-NAME.initramfs``: The deploy ramdisk file containing the
  ironic-python-agent (IPA) service.
- ``$IMAGE-NAME.kernel``: The kernel binary file.

.. note::
   The package based install currently only enables the service when using the
   systemd init system. This can easily be changed if there is an agent
   package which includes upstart or sysv packaging.

.. note::
   Using the ramdisk will require at least 1.5GB of ram
