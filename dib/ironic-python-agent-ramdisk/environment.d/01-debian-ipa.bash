# IPA is built with non-free firmware by default.
export DIB_DEBIAN_COMPONENTS=${DIB_DEBIAN_COMPONENTS:-main,contrib,non-free}

if [[ $DIB_DEBIAN_COMPONENTS =~ non-free ]]; then
    export IPA_DEBIAN_NONFREE=true
else
    export IPA_DEBIAN_NONFREE=false
fi
