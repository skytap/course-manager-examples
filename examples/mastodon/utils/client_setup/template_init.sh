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

#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

apt -y install curl jq

mkdir -p /opt/mastodon
cp configure_hosts_file.rb /opt/mastodon

cat > /etc/systemd/system/configure_hosts_file.service <<EOF
[Unit]
Description=Configure hosts file
After=network-online.target
Wants=network-online.target                                                                    

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c '/usr/bin/ruby /opt/mastodon/configure_hosts_file.rb'

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable configure_hosts_file.service

echo "Done!"

