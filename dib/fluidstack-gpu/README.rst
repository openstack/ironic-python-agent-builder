fluidstack-gpu
==============

DIB element that bundles NVIDIA drivers, CUDA runtime, NCCL, and pre-compiled
``nccl-tests`` binaries into an IPA ramdisk for GPU qualification workloads.

Intended base distribution: **Ubuntu Noble 24.04** (``ubuntu`` + ``--release noble``).

What is installed
-----------------

Runtime (present in final ramdisk):

* ``cuda-drivers-<VER>`` — NVIDIA metapackage (kernel modules, ``nvidia-smi``, compute libs, all from NVIDIA repo at matching versions)
* ``libnccl2`` — NCCL multi-GPU communication library
* ``cuda-cudart-<VER>`` — CUDA runtime library
* ``/usr/local/bin/nccl-tests/`` — pre-compiled nccl-tests binaries

Build-time only (stripped in ``post-install.d``):

* ``cuda-toolkit-<VER>`` — full toolkit used to compile nccl-tests (nvcc, headers)
* ``libnccl-dev`` — NCCL headers

Configuration
-------------

All versions are overridable via environment variables at build time:

.. list-table::
   :header-rows: 1

   * - Variable
     - Default
     - Description
   * - ``DIB_NVIDIA_DRIVER_VERSION``
     - ``570``
     - NVIDIA driver series (e.g. ``535``, ``550``, ``570``)
   * - ``DIB_CUDA_VERSION``
     - ``12-8``
     - CUDA version used for apt package names (dash-separated, e.g. ``12-6``)
   * - ``DIB_NCCL_TESTS_REF``
     - ``master``
     - Git branch/tag of `NVIDIA/nccl-tests <https://github.com/NVIDIA/nccl-tests>`_ to compile

Example build command
---------------------

.. code-block:: bash

    export DIB_DHCP_TIMEOUT=60
    export DIB_IPA_ENABLE_RESCUE=false

    ironic-python-agent-builder \
        --lzma \
        --output ipa-ubuntu-noble-gpu-stable-2026.1-fs \
        --release noble \
        --branch stable/2026.1 \
        --verbose \
        --element fluidstack-gpu \
        ubuntu

Verification
------------

Once booted:

.. code-block:: bash

    nvidia-smi
    /usr/local/bin/nccl-tests/all_reduce_perf -b 1G -e 1G -f 2 -g <N>
