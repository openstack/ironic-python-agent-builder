===========================
 Contributor Documentation
===========================

.. include:: ../../../CONTRIBUTING.rst

Testing changes in DIB images
=============================

Testing a local ironic-python-agent change in :doc:`/admin/dib` requires
rebuilding an image with the following procedure.

#. Make sure your changes are committed to your local repository. DIB needs to
   know a branch name to use (``my-test-branch`` in the example below).

#. Build an image as described in :doc:`/admin/dib`, providing a location of
   your local repository and the branch name, for example:

   .. code-block:: bash

    DIB_REPOLOCATION_ironic_python_agent=/home/user/path/to/repo \
        DIB_REPOREF_ironic_python_agent=my-test-branch \
        ironic-python-agent-builder -o my-ipa --release 9-stream centos

#. A similar process (with one additional variable) can be used for ironic-lib
   changes:

   .. code-block:: bash

    DIB_REPOLOCATION_ironic_lib=/home/user/path/to/repo \
        DIB_REPOREF_ironic_lib=my-test-branch \
        IRONIC_LIB_FROM_SOURCE=true \
        ironic-python-agent-builder -o my-ipa --release 9-stream centos
