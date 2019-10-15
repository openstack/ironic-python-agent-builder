# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import os
import subprocess
import sys


LOCATIONS = [
    os.path.abspath('.'),
    # This accounts for pip installations on Ubuntu that go into /usr/local.
    # This logic converts e.g. /usr/local/bin/ironic-python-agent-builder
    # into /usr/local/share/ironic-python-agent-builder.
    os.path.abspath(os.path.join(os.path.dirname(sys.argv[0]),
                                 '..', 'share',
                                 'ironic-python-agent-builder')),
    # This accounts for system-wide installations to /usr
    os.path.join(sys.prefix, 'share', 'ironic-python-agent-builder'),
]


def find_elements_path():
    for basedir in LOCATIONS:
        final = os.path.join(basedir, 'dib')
        if os.path.exists(os.path.join(final, 'ironic-python-agent-ramdisk')):
            return final

    sys.exit('ironic-python-agent-ramdisk element has not been found in any '
             'of the following locations: %s' % ', '.join(set(LOCATIONS)))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("distribution", help="Distribution to use")
    parser.add_argument("-r", "--release", help="Distribution release to use")
    parser.add_argument("-o", "--output", help="Output base file name",
                        default="ironic-python-agent")
    parser.add_argument("-e", "--element", action='append', default=[],
                        help="Additional DIB element to use")
    # TODO(dtantsur): handle distribution == tinyipa
    os.environ['ELEMENTS_PATH'] = find_elements_path()
    if not os.environ.get('DIB_INSTALLTYPE_pip_and_virtualenv'):
        # DIB updates these to latest versions from source. However, we do the
        # same in our virtualenv, so it's not needed and just increases the
        # size of the image.
        os.environ['DIB_INSTALLTYPE_pip_and_virtualenv'] = 'package'
    args = parser.parse_args()
    if args.release:
        os.environ['DIB_RELEASE'] = args.release
    try:
        subprocess.check_call(['disk-image-create', '-o', args.output,
                               'ironic-python-agent-ramdisk',
                               args.distribution] + args.element)
    except (EnvironmentError, subprocess.CalledProcessError) as exc:
        sys.exit(str(exc))
    except KeyboardInterrupt:
        sys.exit(127)
