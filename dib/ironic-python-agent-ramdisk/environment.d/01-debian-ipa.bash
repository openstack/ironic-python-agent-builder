# IPA is built with non-free firmware by default.
DIB_DEBIAN_NON_FREE=non-free-firmware
export DIB_DEBIAN_COMPONENTS=${DIB_DEBIAN_COMPONENTS:-main,contrib,$DIB_DEBIAN_NON_FREE}

if [[ $DIB_DEBIAN_COMPONENTS =~ non-free ]]; then
    export IPA_DEBIAN_NONFREE=true
else
    export IPA_DEBIAN_NONFREE=false
fi
