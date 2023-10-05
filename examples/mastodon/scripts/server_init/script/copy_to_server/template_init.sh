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

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

export MAST_ROOT="/opt/mastodon"
mkdir -p $MAST_ROOT

apt-get update

echo "=== Access and security"
echo 'user ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
echo 'PasswordAuthentication no' > /etc/ssh/sshd_config
sudo service ssh restart

echo "=== Docker setup"
apt-get -y install ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
[ -f /etc/apt/keyrings/docker.gpg ] && rm /etc/apt/keyrings/docker.gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker $USER

echo "=== Preload images"
docker pull ghcr.io/mastodon/mastodon:v4.1.6 
docker pull postgres:14-alpine
docker pull openresty/openresty:bullseye
docker pull redis:7-alpine
docker pull node:bookworm-slim
docker pull yukimochi/activity-relay:v2.0.3
docker pull tianon/true

echo "=== Certbot setup"
apt-get -y install python3-pip
rm -rf /usr/lib/python3/dist-packages/OpenSSL/
pip install -U pyopenssl
pip install certbot
echo '#!/bin/bash' | tee /etc/cron.daily/certbot-renew
echo '/usr/local/bin/certbot renew' | tee /etc/cron.daily/certbot-renew
chmod 755 /etc/cron.daily/certbot-renew

echo "=== cmsyshelper"
wget https://stcmngrprodfiles.blob.core.windows.net/stc-cmngr-prod-cm-helper/cmsyshelper-1_0_5.tar.gz -O /tmp/cmsyshelper.tgz
tar zxvf /tmp/cmsyshelper.tgz -C /tmp
mv /tmp/cmsyshelper-* /usr/sbin/cmsyshelper
chmod +x /usr/sbin/cmsyshelper
cat > /etc/systemd/system/cmsyshelper.service <<EOF
[Unit]
Description=Skytap Course Manager System Helper

[Service]
ExecStart=/usr/sbin/cmsyshelper
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl start cmsyshelper.service
systemctl enable cmsyshelper.service

echo "=== Other setup"
apt -y install jq curl
rmmod floppy || true
echo "blacklist floppy" > /etc/modprobe.d/blacklist-floppy.conf
dpkg-reconfigure initramfs-tools

echo "=== Setup init"
mkdir -p $MAST_ROOT/init
cp $PWD/* $MAST_ROOT/init

echo "=== Done!"