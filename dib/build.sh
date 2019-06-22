#!/bin/bash

#The path for location of ironic-python-agent-ramdisk in ironic-python-image-builder
#is set using environment variable.
export ELEMENTS_PATH=${ELEMENTS_PATH:-`.`}

#The command to build image using disk-image-builder.
#Run the command to build the image giving the argument(OS name)
#For example:  ./build.sh ubuntu
disk-image-create -o ironic-python-agent.qcow ironic-python-agent-ramdisk $@
