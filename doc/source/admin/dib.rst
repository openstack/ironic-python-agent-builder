diskimage-builder images
========================

Images built using diskimage-builder_ are recommended for production use on
real hardware.

Building
--------

... with the helper script
~~~~~~~~~~~~~~~~~~~~~~~~~~

To build an image using ``ironic-python-agent-builder``, run:

.. code-block:: shell

    ironic-python-agent-builder <distribution, e.g. ubuntu>

You can add other diskimage-builder_ elements via the ``-e`` flag:

.. code-block:: shell

    ironic-python-agent-builder -e <extra-element> --release 8 centos-minimal

You can specify the base name of the target images:

.. code-block:: shell

    ironic-python-agent-builder -o my-ipa --release 8 centos-minimal

You can specify the arch of the target image by setting ``ARCH`` environment
variable (default is amd64):

.. code-block:: shell

    export ARCH=aarch64
    ironic-python-agent-builder -o my-ipa fedora

... with diskimage-builder
~~~~~~~~~~~~~~~~~~~~~~~~~~

You can also use diskimage-builder_ directly. First you need to set the
``ELEMENTS_PATH`` variable to the correct location:

* If installed with ``pip install --user``, use:

  .. code-block:: bash

    export ELEMENTS_PATH=$HOME/.local/share/ironic-python-agent-builder/dib

* On Fedora/CentOS/RHEL (installed via ``sudo pip install`` or from packages):

  .. code-block:: bash

    export ELEMENTS_PATH=/usr/share/ironic-python-agent-builder/dib

* On Debian and its derivatives, if installed with ``sudo pip install``:

  .. code-block:: bash

    export ELEMENTS_PATH=/usr/local/share/ironic-python-agent-builder/dib

Now you can build an image adding the ``ironic-python-agent-ramdisk`` element,
for example:

.. code-block:: shell

    export DIB_RELEASE=8
    disk-image-create -o ironic-python-agent \
        ironic-python-agent-ramdisk centos-minimal

To use a specific branch of ironic-python-agent, use:

.. code-block:: bash

    export DIB_REPOREF_ironic_python_agent=origin/stable/queens
    export DIB_REPOREF_requirements=origin/stable/queens

To build image for architectures other than amd64, you can either set the
``ARCH`` environment variable or use ``-a`` to specify the target
architecture:

.. code-block:: shell

    disk-image-create -a arm64 -o ironic-python-agent \
        ironic-python-agent-ramdisk fedora

ISO Images
~~~~~~~~~~

Additionally, the IPA ramdisk can be packaged inside of an ISO for use with
some virtual media drivers. Use the ``iso-image-create`` utility, passing it
the initrd and the kernel, for example:

.. code-block:: console

  ./tools/iso-image-create -o /path/to/output.iso -i /path/to/ipa.initrd -k /path/to/ipa.kernel

This is a generic tool that can be used to combine any initrd and kernel into
a suitable ISO for booting, and so should work against any IPA ramdisk.

Advanced options
----------------

Disabling rescue
~~~~~~~~~~~~~~~~

By default rescue mode is enabled in the images. Since it allows to set root
password on the ramdisk by anyone on the network, you may disable it if the
rescue feature is not supported. Set the following before building the image:

.. code-block:: bash

    export DIB_IPA_ENABLE_RESCUE=false

SSH access
~~~~~~~~~~

SSH access can be added to DIB built IPA images with the dynamic-login_
or the devuser_ element.

The *dynamic-login* element allows the operator to inject an SSH key at boot
time via the kernel command line parameters:

* Add ``sshkey="ssh-rsa <your public key here>"`` to ``pxe_append_params``
  setting in the ``ironic.conf`` file. Disabling SELinux is required for
  systems where it is enabled, it can be done with ``selinux=0``.

  .. warning:: Quotation marks around the public key are important!

* Restart the ironic-conductor.

.. note::
   This element is added to the published images by default.

The *devuser* element allows creating a user at build time, for example:

.. code-block:: bash

  export DIB_DEV_USER_USERNAME=username
  export DIB_DEV_USER_PWDLESS_SUDO=yes
  export DIB_DEV_USER_AUTHORIZED_KEYS=$HOME/.ssh/id_rsa.pub
  disk-image-create debian ironic-python-agent-ramdisk devuser

Consistent Network Interface Naming
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Base cloud images normally disable consistent network interface naming
by inserting an empty udev rule. Include ``stable-interface-names`` element
if you want to have consistent network interface naming whenever it is
required for instance image or deploy image.

.. code-block:: bash

    ironic-python-agent-builder -e stable-interface-names --release 8 centos-minimal


.. _diskimage-builder: https://docs.openstack.org/diskimage-builder
.. _dynamic-login: https://docs.openstack.org/diskimage-builder/latest/elements/dynamic-login/README.html
.. _devuser: https://docs.openstack.org/diskimage-builder/latest/elements/devuser/README.html
