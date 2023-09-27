#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

if [ "$((pstree -s $$ | grep -i ssh) || echo console)" != "console" ]; then
  echo "Please run from the console"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

export MAST_ROOT="/opt/mastodon"
mkdir -p $MAST_ROOT

apt-get update

echo "=== Access and security"
apt-get -y install openssh-server ifupdown
iptables -A INPUT -p tcp --dport 22 -s 10.0.0.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -s 127.0.0.0/8 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j DROP
iptables-save > /etc/iptables.rules
mkdir -p ~/.ssh
cat $PWD/id_rsa.pub >> ~/.ssh/authorized_keys
echo '#!/bin/bash' > /etc/network/if-pre-up.d/iptables-rules
echo 'iptables-restore < /etc/iptables.rules' >> /etc/network/if-pre-up.d/iptables-rules
echo 'exit 0' >> /etc/network/if-pre-up.d/iptables-rules
chmod 755 /etc/network/if-pre-up.d/iptables-rules
echo 'user ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

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

# Commenting out automatic running of mast_init via systemd because we decided to have the user initiate through a button press instead.
# cat > /etc/systemd/system/mast_init.service <<EOF
# [Unit]
# Description=Mastodon init
# After=docker.service
# Requires=docker.service
# Before=getty@tty1.service getty@tty2.service getty@tty3.service getty@tty4.service getty@tty5.service getty@tty6.service

# [Service]
# ExecStart=$MAST_ROOT/init/mast_init.sh
# Type=oneshot

# [Install]
# WantedBy=multi-user.target
# EOF

# systemctl enable mast_init.service

echo "=== Done!"