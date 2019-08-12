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
    '.',
    os.path.join(sys.prefix, 'share', 'ironic-python-agent-builder'),
]


def find_elements_path():
    for basedir in LOCATIONS:
        final = os.path.join(basedir, 'dib')
        if os.path.exists(os.path.join(final, 'ironic-python-agent-ramdisk')):
            return final

    sys.exit('ironic-python-agent-ramdisk element has not been found in any '
             'of the following locations: %s' % ', '.join(LOCATIONS))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("distribution", help="Distribution to use")
    parser.add_argument("-o", "--output", help="Output base file name",
                        default="ironic-python-agent")
    parser.add_argument("-e", "--element", action='append', default=[],
                        help="Additional DIB element to use")
    # TODO(dtantsur): handle distribution == tinyipa
    os.environ['ELEMENTS_PATH'] = find_elements_path()
    args = parser.parse_args()
    try:
        subprocess.check_call(['disk-image-create', '-o', args.output,
                               'ironic-python-agent-ramdisk',
                               args.distribution] + args.element)
    except (EnvironmentError, subprocess.CalledProcessError) as exc:
        sys.exit(str(exc))
    except KeyboardInterrupt:
        sys.exit(127)
