#!/bin/bash

set -eux
set -o pipefail

echo "Adding rescue user with root privileges..."
crypted_pass=$(</etc/ipa-rescue-config/ipa-rescue-password)

# 'rescue' user should belong to sudo group
# on RH based it's wheel, on Debian based it's sudo
sudo_group=wheel
if [ "$(grep -Ei 'debian|ubuntu' /etc/*release)" ] ; then
    sudo_group=sudo
fi

useradd -m rescue -G $sudo_group -p $crypted_pass
echo "rescue ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/rescue
