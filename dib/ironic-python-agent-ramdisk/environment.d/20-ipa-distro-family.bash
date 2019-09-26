# TODO(dtantsur): verify if opensuse can be added here
if [[ $DISTRO_NAME =~ (fedora|centos|centos7|rhel|rhel7) ]]; then
    export IPA_DISTRO_FAMILY=rh
else
    export IPA_DISTRO_FAMILY=other
fi
