# IPA is built with non-free firmware by default.
DIB_DEBIAN_NON_FREE=non-free-firmware
if [[ "$DIB_RELEASE" == "bullseye" ]]; then
    # Starting with bookworm, firmware is in a separate repository
    DIB_DEBIAN_NON_FREE=non-free
fi
export DIB_DEBIAN_COMPONENTS=${DIB_DEBIAN_COMPONENTS:-main,contrib,$DIB_DEBIAN_NON_FREE}

if [[ $DIB_DEBIAN_COMPONENTS =~ non-free ]]; then
    export IPA_DEBIAN_NONFREE=true
else
    export IPA_DEBIAN_NONFREE=false
fi
