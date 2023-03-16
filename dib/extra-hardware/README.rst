========================================
Ironic Python Agent (IPA) Extra Hardware
========================================

This element adds the `hardware <https://pypi.python.org/pypi/hardware>`_
python package to the Ironic Python Agent (IPA) ramdisk. It also installs
several package dependencies of the ``hardware`` module.

The ``hardware`` package provides improved hardware introspection capabilities
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
* ``DIB_IPA_HARDWARE_RDO`` set to ``0`` to prevent the latest RDO package repositories
  being installed on CentOS-9-Stream (ignored when ``DIB_YUM_REPO_CONF`` is set).
