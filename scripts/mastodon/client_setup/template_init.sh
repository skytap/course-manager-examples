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

