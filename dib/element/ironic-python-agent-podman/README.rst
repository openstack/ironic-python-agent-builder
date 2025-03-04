# ironic-python-agent-podman
Adds Podman support and configuration files to ironic-python-agent-ramdisk.

## Compatibility
This DIB element currently supports Debian-based images only. Additional
distribution support may be added in the future.

## ironic-python-agent-config
allow_arbitrary_containers:
- Description: Defines whether arbitrary containers are allowed.
Set to true or false.
- Environment Variable: `DIB_ALLOW_ARBITRARY_CONTAINERS`
- Default: `false`

allowed_containers:
- Description: Specifies a list of allowed container image URLs
(ex "image1-url,image2-url").
- Environment Variable: `DIB_ALLOWED_CONTAINERS`
- Default: Empty string (`""`)

container_steps_file:

- Description: Specifies the path in the ram to the YAML file containing
 container steps to be executed.
- Environment Variable: `DIB_CONTAINER_STEPS_FILE`
- Default: `/etc/ironic-python-agent.d/mysteps.yaml`

runner:

- Description: Defines the container runtime to use, such as podman or docker.
- Environment Variable: `DIB_RUNNER`
- Default: `podman`

pull_options:

- Description: Container pull options (e.g., --tls-verify=false).
- Environment Variable: `DIB_PULL_OPTIONS`
- Default: `--tls-verify=false`

run_options:

- Description: Options passed when running the container
(e.g., --rm --network=host).
- Environment Variable: `DIB_RUN_OPTIONS`
- Default: `--rm --network=host --tls-verify=false`

## ironic-python-agent-podman
podman_conf_file:
- Description: The path to the configuration file created in the RAM
- Environment Variable: `DIB_PODMAN_CONF_FILE`
- Default `/etc/containers/containers.conf`

## ironic-python-agent-steps
steps_file_path:
- Description: Path to the local stepfile to be copied to the RAM
- Environment Variable: `DIB_STEPS_FILE_PATH`
- Default `/etc/mysteps.yaml`

### Example mysteps.yaml
```
steps:
  - name: manage_container_cleanup
    image: docker://172.24.4.1:5000/cleaning-image:latest
    interface: deploy
    reboot_requested: true
    pull_options:
      - --tls-verify=false
    run_options:
      - --rm
      - --network=host
      - --tls-verify=false
    abortable: true
    priority: 20
  - name: manage_container_cleanup2
    image: docker://172.24.4.1:5000/cleaning-image2:latest
    interface: deploy
    reboot_requested: true
    pull_options:
      - --tls-verify=false
    run_options:
      - --rm
      - --network=host
      - --tls-verify=false
    abortable: true
    priority: 10

```

### Customization
You can override any of the default values by setting the corresponding
environment variables during the build process. This allows the configuration
to be dynamically adapted without modifying the script.
