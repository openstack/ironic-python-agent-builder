# Podman Config
PODMAN_CONF_INSIDEDIR=/etc/containers

export PODMAN_CONF_FILE=${DIB_IPA_PODMAN_CONF_FILE:-$TMP_BUILD_DIR/mnt/$PODMAN_CONF_INSIDEDIR/containers.conf}

# Ipa Config
IPA_CONF_INSIDEDIR=/etc/ironic-python-agent.d
export IPA_CONFFILE=$TMP_BUILD_DIR/mnt/$IPA_CONF_INSIDEDIR/ironic_python_agent.conf

export ALLOW_ARBITRARY_CONTAINERS="${DIB_ALLOW_ARBITRARY_CONTAINERS:-false}"
export ALLOWED_CONTAINERS="${DIB_ALLOWED_CONTAINERS:-""}"
export CONTAINER_STEPS_FILE="${DIB_CONTAINER_STEPS_FILE:-/etc/ironic-python-agent.d/mysteps.yaml}"
export RUNNER="${DIB_RUNNER:-podman}"
export PULL_OPTIONS="${DIB_PULL_OPTIONS:---tls-verify=false}"
export RUN_OPTIONS="${DIB_RUN_OPTIONS:---rm --network=host --tls-verify=false}"

# Steps Config
STEPS_INSIDEDIR=/etc/ironic-python-agent.d
export STEPS_FILE=$TMP_BUILD_DIR/mnt/$STEPS_INSIDEDIR/mysteps.yaml

export STEPS_FILE_PATH="${DIB_STEPS_FILE_PATH:-/etc/mysteps.yaml}"
