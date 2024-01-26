diskimage-builder images
========================

Images built using diskimage-builder_ are recommended for production use on
real hardware. The recommended distributions are:

* CentOS Stream 9
* Debian Bookworm (``debian-minimal`` element)

The following should work but receive only limited testing and support:

* Ubuntu 20.04 Focal
* Debian Bullseye (``debian-minimal`` element)

Building
--------

... with the helper script
~~~~~~~~~~~~~~~~~~~~~~~~~~

To build an image using ``ironic-python-agent-builder``, run:

.. code-block:: shell

    ironic-python-agent-builder <distribution, e.g. ubuntu>

You can add other diskimage-builder_ elements via the ``-e`` flag:

.. code-block:: shell

    ironic-python-agent-builder -e <extra-element> --release 9-stream centos

You can specify the base name of the target images:

.. code-block:: shell

    ironic-python-agent-builder -o my-ipa --release 9-stream centos

You can specify the arch of the target image by setting ``ARCH`` environment
variable (default is amd64):

.. code-block:: shell

    export ARCH=aarch64
    ironic-python-agent-builder -o my-ipa --release 9-stream centos

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

    export DIB_RELEASE=9-stream
    disk-image-create -o ironic-python-agent \
        ironic-python-agent-ramdisk centos

To use a specific branch of ironic-python-agent, use:

.. code-block:: bash

    export DIB_REPOREF_ironic_python_agent=origin/stable/queens
    export DIB_REPOREF_requirements=origin/stable/queens

To build ironic-lib from source, do:

.. code-block:: bash

    export IRONIC_LIB_FROM_SOURCE=true
    # Optionally:
    #export DIB_REPOREF_ironic_lib=<branch>

To build image for architectures other than amd64, you can either set the
``ARCH`` environment variable or use ``-a`` to specify the target
architecture:

.. code-block:: shell

    disk-image-create -a arm64 -o ironic-python-agent \
        ironic-python-agent-ramdisk fedora

ISO Images
~~~~~~~~~~

Additionally, the IPA ramdisk can be packaged inside of an ISO for use with
some virtual media drivers. Use the ``iso-image-create`` script in
``ironic-python-agent-builder`` repository, passing it the initrd and the
kernel, for example:

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
  setting in the ``ironic.conf`` file.

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

    ironic-python-agent-builder -e stable-interface-names --release 9-stream centos


.. _diskimage-builder: https://docs.openstack.org/diskimage-builder
.. _dynamic-login: https://docs.openstack.org/diskimage-builder/latest/elements/dynamic-login/README.html
.. _devuser: https://docs.openstack.org/diskimage-builder/latest/elements/devuser/README.html

Firmware Removal
~~~~~~~~~~~~~~~~

By default the element removes some firmware blobs to reduce the image size.
The list can be found below this paragraph. The majority of these firmware
images are used by SoCs, WI-FI chips, some GPUs and Smartnics which are
unlikely to be encountered. If you want to override this, change the
``IPA_REMOVE_FIRMWARE`` environment variable to a comma-separated list
of directories or files under ``/usr/lib/firmware``.
Set it to an empty string to disable firmware removal.

Firmware removed:

* ``amdgpu``
* ``netronome``
* ``qcom``
* ``ti-communication``
* ``ti-keystone``
* ``ueagle-atm``
* ``rsi``
* ``mrvl``
* ``brcm``
* ``mediatek``
* ``ath10k``
* ``rtlwifi``

Available Elements
------------------

Ironic Python Agent (IPA) Extra Hardware
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This element adds the `hardware <https://pypi.python.org/pypi/hardware>`_
python package to the Ironic Python Agent (IPA) ramdisk. It also installs
several package dependencies of the ``hardware`` module.

The ``hardware`` package provides improves hardware introspection capabilities
and supports benchmarking. This functionality may be enabled by adding the
``extra-hardware`` collector in the ``[DEFAULT] inspection_collectors`` option
or the ``ipa-inspection-collectors`` kernel command line argument.

The following environment variables may be set to configure the element when
doing a source-based installation:

* ``DIB_IPA_HARDWARE_PACKAGE`` the full ``hardware`` Python package descriptor
  to use. If unset, ``DIB_IPA_HARDWARE_VERSION`` will be used.
* ``DIB_IPA_HARDWARE_VERSION`` the version of the ``hardware`` package to
  install when ``DIB_IPA_HARDWARE_PACKAGE`` is unset. If unset, the latest
  version will be installed.

ironic-python-agent-ramdisk
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Builds a ramdisk with ironic-python-agent.

More information can be found at:
https://docs.openstack.org/ironic-python-agent/latest/

Beyond installing the ironic-python-agent, this element does the following:

* Installs the ``dhcp-all-interfaces`` so the node, upon booting, attempts to
  obtain an IP address on all available network interfaces.
* Disables the ``iptables`` service on SysV and systemd based systems.
* Disables the ``ufw`` service on Upstart based systems.
* Installs packages required for the operation of the ironic-python-agent::
  ``qemu-utils`` ``parted`` ``hdparm`` ``util-linux``
* When installing from source, ``python-dev`` and ``gcc`` are also installed
  in order to support source based installation of ironic-python-agent and its
  dependencies.
* Install the certificate if any, which is set to the environment variable
  ``DIB_IPA_CERT`` for validating the authenticity by ironic-python-agent. The
  certificate can be self-signed certificate or CA certificate.
* Compresses initramfs with command specified in environment variable
  ``DIB_IPA_COMPRESS_CMD``, which is 'gzip' by default. This command should
  listen for raw data from stdin and write compressed data to stdout. Command
  can be with arguments.
* Configures rescue mode if ``DIB_IPA_ENABLE_RESCUE`` is not set to ``false``.

This element outputs two files:

* ``$IMAGE-NAME.initramfs``: The deploy ramdisk file containing the
  ironic-python-agent (IPA) service.
* ``$IMAGE-NAME.kernel``: The kernel binary file.

.. note::
   The package based install currently only enables the service when using the
   systemd init system. This can easily be changed if there is an agent
   package which includes upstart or sysv packaging.

.. note::
   Using the ramdisk will require at least 1.5GB of ram

ironic-python-agent-tls
~~~~~~~~~~~~~~~~~~~~~~~

Adds TLS support to ironic-python-agent-ramdisk.

By default this element will enable TLS API support in IPA with a self-signed
certificate and key created at build time.

Optionally, you can provide your own SSL certificate and key, and optionally
CA, via the following environment variables. They should be set to an
accessible path on the build systems filesystem. If set, they will be copied
into the built ramdisk, and IPA will be configured to use them.

The environment variables are:

* ``DIB_IPA_CERT_FILE`` should point to the TLS certificate for ramdisk use.
* ``DIB_IPA_KEY_FILE`` should point to the private key matching
  ``DIB_IPA_CERT_FILE``.

You can configure the generated certificate with the following environment
variables:

* ``DIB_IPA_CERT_HOSTNAME`` the CN for the generated certificate. Defaults to
  "ipa-ramdisk.example.com".
* ``DIB_IPA_CERT_EXPIRATION`` expiration, in days, for the certificate.
  Defaults to 1095 (three years).

Note that the certificates generated by this element are self-signed, and
any nodes using them will need to set agent_verify_ca=False in driver_info.

This element can also configure client certificate validation in IPA. If you
wish to validate client certificates, set ``DIB_IPA_CA_FILE`` to a CA file
you wish IPA client connections to be validated against. This CA file will
be copied into the built ramdisk, and IPA will be configured to use it.

