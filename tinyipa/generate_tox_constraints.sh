#!/bin/bash -eu

SCRIPT_NAME=$(basename $0)
COMMON_ROOT=$(dirname $0)
DESTINATION="$1"
TOX_INI=${2:-tox.ini}

copy() {
    local src=$1
    local destination=$2

    if test -z "${src}"; then
        return 1
    fi

    if test -e "${src}"; then
        log "File '${src}' exists. Using as upper-constraints."
        cp "${src}" "${destination}"
    else
        log "File '${src}' not found. Skipping local file strategy."
        return 1
    fi
    return 0
}

download() {
    local url=$1
    local destination=$2

    if test -z "${url}"; then
        return 1
    else
        log "Downloading from '${url}'"
        curl -L ${url} -o "${destination}"
    fi
    return 0
}

log() {
    echo "${SCRIPT_NAME}: ${@}"
}

fail() {
    log ${@}
    exit 1
}

tox_constraints_is_not_null() {
    test "${TOX_CONSTRAINTS_FILE:-""}" != ""
}

copy_uc() {
    copy "${TOX_CONSTRAINTS_FILE:-""}" "${DESTINATION}"
}

download_uc() {
    download "${TOX_CONSTRAINTS_FILE:-""}" "${DESTINATION}"
}

copy_new_requirements_uc() {
    if [ -e "/opt/stack/new/requirements" ]; then
        copy "/opt/stack/new/requirements/upper-constraints.txt" "${DESTINATION}"
    elif [ -e "/opt/stack/requirements" ]; then
        copy "/opt/stack/requirements/upper-constraints.txt" "${DESTINATION}"
    else
        log "No local requirements repository, will download upper-constraints"
        # Allow the caller to handle the failure
        return 1
    fi
}

download_from_tox_ini_url() {
    local url
    # NOTE(mmitchell): This extracts the URL defined as the default value for
    #                  TOX_CONSTRAINTS_FILE in tox.ini. This is used by image
    #                  builders to avoid duplicating the default value in multiple
    #                  scripts. This is specially done to leverage the release
    #                  tools that automatically update the tox.ini when projects
    #                  are released.
    url=$(sed -n 's/^.*{env:TOX_CONSTRAINTS_FILE\:\([^}]*\)}.*$/\1/p' $TOX_INI | head -n1)
    log "tox.ini indicates '${url}' as fallback."
    download "${url}" "${DESTINATION}"
}

log "Generating local constraints file..."

if tox_constraints_is_not_null; then
    log "TOX_CONSTRAINTS_FILE is defined as '${TOX_CONSTRAINTS_FILE:-""}'"
    copy_uc || download_uc || fail "Failed to copy or download file indicated in TOX_CONSTRAINTS_FILE."
else
    log "TOX_CONSTRAINTS_FILE is not defined. Using fallback strategies."

    copy_new_requirements_uc || \
        download_from_tox_ini_url || \
        fail "Failed to download upper-constraints.txt from either CI or tox.ini location."
fi
