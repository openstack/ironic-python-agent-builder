
# sysbench is installed by default to preserve existing behaviour, but it
# is only used by the opt-in cpu/mem benchmarks and is only available in
# EPEL on RHEL/CentOS Stream (not in the base repos), so it can be
# disabled with DIB_IPA_HARDWARE_SYSBENCH=0
export DIB_IPA_HARDWARE_SYSBENCH=${DIB_IPA_HARDWARE_SYSBENCH:-1}

if [[ "${DISTRO_NAME}" =~ "centos" ]]; then

    if [ -n "${DIB_YUM_REPO_CONF:-}" ] ; then
        # Always disable if DIB_YUM_REPO_CONF is defined
        export DIB_IPA_HARDWARE_RDO=0
    else
        # Default to enabled, but overridable by the host
        export DIB_IPA_HARDWARE_RDO=${DIB_IPA_HARDWARE_RDO:-1}
    fi
else
    # Always disable if not centos
    export DIB_IPA_HARDWARE_RDO=0
fi
