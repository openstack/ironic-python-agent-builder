# TODO(dtantsur): verify if opensuse can be added here
if [[ $DISTRO_NAME =~ (fedora|centos|centos7|rhel|rhel7) ]]; then
    export IPA_DISTRO_FAMILY=rh
else
    export IPA_DISTRO_FAMILY=other
fi

# NOTE(rpittau) force Python version to 3 for debian
if [[ $DISTRO_NAME =~ debian ]]; then
  DIB_PYTHON_VERSION=3
  export DIB_PYTHON_VERSION
fi
