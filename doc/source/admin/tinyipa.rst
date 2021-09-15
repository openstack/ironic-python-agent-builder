TinyIPA images
==============

TinyIPA is an `Ironic Python Agent`_ image based on TinyCoreLinux_. It is very
lightweight and thus very suitable for CI use. It may lack necessary drivers
and the build process uses insecure communication, thus these images are not
recommended for production usage.

Requirements
------------

You need to have a git clone of **ironic-python-agent-builder**:

.. code-block:: shell

    git clone https://opendev.org/openstack/ironic-python-agent-builder
    cd ironic-python-agent-builder/tinyipa

Then you need to install some utilities. For the main build script:

* wget
* pip
* unzip
* sudo
* awk
* mksquashfs

For building an ISO you'll also need:

* mkisofs, genisoimage, or xorrisofs

Building
--------

Building ramdisk
~~~~~~~~~~~~~~~~

To create a new ramdisk, run:

.. code-block:: shell

    make

or:

.. code-block:: shell

    ./build-tinyipa.sh && ./finalise-tinyipa.sh

This will create two new files once completed:

* ``tinyipa.vmlinuz`` - the kernel image
* ``tinyipa.gz`` - the initramfs image

Upload them to the Image service or another location where you want them to be
hosted (an HTTP or FILE location in case of standalone ironic).

Building ISO
~~~~~~~~~~~~

Once you've built tinyIPA it is possible to pack it into an ISO if required. To
create a bootable ISO, run:

.. code-block:: shell

    make iso

or:

.. code-block:: shell

    ./build-iso.sh

This will create one new file once completed:

* ``tinyipa.iso``


Cleaning up
~~~~~~~~~~~

To clean up the whole build environment, run:

.. code-block:: shell

    make clean

For cleaning up just the iso or just the ramdisk build:

.. code-block:: shell

    make clean_iso

or:

.. code-block:: shell

    make clean_build

Advanced options
----------------

Enabling/disabling SSH access to the ramdisk
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

By default tinyIPA will be built with OpenSSH server installed but no
public SSH keys authorized to access it.

If you want to enable SSH access to the image, set ``AUTHORIZE_SSH`` variable
in your shell before building tinyIPA:

.. code-block:: bash

    export AUTHORIZE_SSH=true

By default it will use public RSA or DSA keys of the user running the build.
To provide a different public SSH key, export path to it in your shell before
building tinyIPA:

.. code-block:: bash

    export SSH_PUBLIC_KEY=<full-path-to-public-key>

If you want to disable SSH altogether, set ``INSTALL_SSH`` variable in your
shell to ``false`` before building tinyIPA:

.. code-block:: bash

    export INSTALL_SSH=false

If you want to change the SSH access of a previously built tinyIPA image,
use the make target ``addssh``:

.. code-block:: shell

    make addssh

This command will either use a local image specified by the
``TINYIPA_RAMDISK_FILE`` environment variable or download the version
specified by the ``BRANCH_PATH`` environment variable (e.g. ``master`` or
``stable-queens``) from `tarballs.openstack.org
<https://tarballs.openstack.org/ironic-python-agent/tinyipa/files/>`_.
It will install and configure OpenSSH if needed and add public SSH keys for
the user named ``tc`` using either the same ``SSH_PUBLIC_KEY`` shell variable
or the public keys of the local user.

Enabling biosdevname in the ramdisk
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you want to collect BIOS given names of NICs in the inventory, set
``TINYIPA_REQUIRE_BIOSDEVNAME`` variable in your shell before building tinyIPA:

.. code-block:: bash

    export TINYIPA_REQUIRE_BIOSDEVNAME=true

Using ironic-lib from source
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ironic-lib_ contains important parts of the provisioning logic. If you would
like to build an IPA image with your local checkout of ironic-lib_, export
the following variable:

.. code-block:: bash

    export IRONIC_LIB_SOURCE=/absolute/path/to/ironic-lib/checkout


.. _Ironic Python Agent: https://docs.openstack.org/ironic-python-agent
.. _TinyCoreLinux: http://tinycorelinux.net
.. _ironic-lib: https://opendev.org/openstack/ironic-lib
