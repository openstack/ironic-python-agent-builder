if [[ $DISTRO_NAME =~ (fedora|centos|rhel) ]]; then
    export IPA_DISTRO_FAMILY=rh
else
    export IPA_DISTRO_FAMILY=other
fi

if [[ ${DISTRO_NAME} =~ (centos|rhel) ]]; then
    export DIB_DHCP_NETWORK_MANAGER_AUTO=${DIB_DHCP_NETWORK_MANAGER_AUTO:-true}
fi

# NOTE(rpittau) force Python version to 3 for debian
if [[ $DISTRO_NAME =~ debian ]]; then
  DIB_PYTHON_VERSION=3
  export DIB_PYTHON_VERSION
fi
