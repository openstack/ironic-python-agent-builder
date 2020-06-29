if [[ "$DISTRO_NAME" == "centos" ]] && [[ "$DIB_RELEASE" == 8 ]]; then
    # Disable EPEL unless enabled explicitly
    export DIB_EPEL_DISABLED=${DIB_EPEL_DISABLED:-1}
fi
