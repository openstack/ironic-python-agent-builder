# GPU stack version pins — edit this file to update component versions.
# All DIB_* variables can be overridden at build time via environment.

# NVIDIA driver — must match an available nvidia-driver-pinning-* package
export DIB_NVIDIA_DRIVER_VERSION=${DIB_NVIDIA_DRIVER_VERSION:-590.48.01}

# CUDA toolkit (dash-separated apt package suffix, e.g. 13-1 → cuda-toolkit-13-1)
export DIB_CUDA_VERSION=${DIB_CUDA_VERSION:-13-1}

# NCCL tests git ref compiled into the image
export DIB_NCCL_TESTS_REF=${DIB_NCCL_TESTS_REF:-master}

# GDRCopy (package revision format: <semver>-<rev>)
export DIB_GDRCOPY_VERSION=${DIB_GDRCOPY_VERSION:-2.5.1-1}

# Feature flags
export DIB_ENABLE_GDRCOPY=${DIB_ENABLE_GDRCOPY:-true}
export DIB_ENABLE_DCGM=${DIB_ENABLE_DCGM:-true}
export DIB_ENABLE_PEERMEM=${DIB_ENABLE_PEERMEM:-false}
