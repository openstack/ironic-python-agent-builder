
if [[ "${DISTRO_NAME}${DIB_RELEASE}" =~ "centos9" ]]; then

    if [ -n "${DIB_YUM_REPO_CONF:-}" ] ; then
        # Always disable if DIB_YUM_REPO_CONF is defined
        export DIB_IPA_HARDWARE_RDO=0
    else
        # Default to enabled, but overridable by the host
        export DIB_IPA_HARDWARE_RDO=${DIB_IPA_HARDWARE_RDO:-1}
    fi
else
    # Always disable if not centos-9
    export DIB_IPA_HARDWARE_RDO=0
fi
