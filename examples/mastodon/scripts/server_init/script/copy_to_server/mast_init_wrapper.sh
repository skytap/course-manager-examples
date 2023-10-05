#!/bin/bash

# Copyright 2023 Skytap Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cd /opt/mastodon/init
sudo ./mast_init.sh > /tmp/mast_init_output.txt 2>&1

if [ "$?" -gt "0" ]; then
  echo "Provisioning the Mastodon server failed!" >&2
  echo ""
  echo "Details:"
  cat /tmp/mast_init_output.txt
  exit 1
else
  echo "Provisioning the Mastodon server was successful!"
  echo ""
  echo "Details:"
  cat /tmp/mast_init_output.txt
  exit 0
fi