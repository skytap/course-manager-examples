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

export MAST_ROOT="/opt/mastodon"
export DATA_ROOT="$MAST_ROOT/data"

DONE_FILE=$MAST_ROOT/done.txt

if [ -f "$DONE_FILE" ]; then
  echo "Setup is already done"
  exit 0
fi

if [ ! -d "$MAST_ROOT/init" ]; then
  echo "$MAST_ROOT/init not found - be sure to run the template setup script first"
  exit 1
fi

# Hardcoded values for shared Mast server
# For normal operation, comment this out and uncomment the "Normal operation" section
# export _RELAY_HOSTNAME="mast-relay.coursemanagerteam.skytapdns.com"
# export _APP_HOSTNAME="mast.coursemanagerteam.skytapdns.com"
# export _ADMIN_EMAIL="mgoldman@skytap.com"
# export _ADMIN_PASSWD="Password1!"

# Normal operation - relay disabled and automatic config from Skytap/CM metadata
SKYTAP_METADATA=$(curl -s http://gw/skytap)
CM_METADATA_URL=$(jq -r ".configuration_user_data | fromjson | .metadata_url" <<< "$SKYTAP_METADATA")
CM_METADATA=$(curl -s $CM_METADATA_URL | jq -r ".metadata")
export _SMTP_SERVER=smtp.sendgrid.net
export _SMTP_PORT=587
export _SMTP_LOGIN=apikey
export _SMTP_PASSWORD=$(jq -r ".sg_key" <<< "$CM_METADATA")
export _SMTP_AUTH_METHOD=plain
export _SMTP_OPENSSL_VERIFY_MODE=peer
export _SMTP_ENABLE_STARTTLS=auto
export _APP_HOSTNAME=$(jq -r ".interfaces[0] .public_ip_attachments[0] .dns_name" <<< "$SKYTAP_METADATA")
export _ADMIN_EMAIL=$(jq -r ".mastodon_admin_email" <<< "$CM_METADATA")
export _ADMIN_PASSWD=$(jq -r ".mastodon_admin_password" <<< "$CM_METADATA")
export _SVC_USER_EMAIL=coursemanager@skytap.com
export _SVC_USER_PASSWD=$(jq -r ".mastodon_admin_password" <<< "$CM_METADATA")
export _SSH_PUBLIC_KEY=$(jq -r ".mastodon_ssh_public_key" <<< "$CM_METADATA")
export _DB_HOST=$(jq -r ".db_fqdn" <<< "$CM_METADATA")
export _DB_PORT=5432
export _DB_NAME=$(jq -r ".db_name" <<< "$CM_METADATA")
export _DB_USER=$(jq -r ".db_username" <<< "$CM_METADATA")
export _DB_PASS=$(jq -r ".db_password" <<< "$CM_METADATA")

# These values will stay hardcoded for now
export _ADMIN_USER="admin"
export _SVC_USER="service_user"
export _SMTP_FROM_ADDRESS="noreply@skytap-portal.com"

mkdir -p $MAST_ROOT
cd $MAST_ROOT

echo "=== Clean up from any previous attempts"
[ -f docker-compose.yml ] && [ -f .env.production ] && (docker compose down; docker compose rm; true)
rm -rf $DATA_ROOT/*
docker rm -f pgsetup || true
docker rm -f ngle || true

echo "=== Setup SSH"
mkdir -p ~/.ssh
echo "$_SSH_PUBLIC_KEY" >> ~/.ssh/authorized_keys

echo "=== Setup destination directory structure"
mkdir -p $DATA_ROOT/mastodon/public/system
chown -R 991:991 $DATA_ROOT/mastodon

echo "=== Setup docker-compose files"
cp $MAST_ROOT/init/docker-compose.yml $MAST_ROOT

if [ ! -z "$_DB_HOST" ] || [ -z "$_RELAY_HOSTNAME" ]; then
  echo "version: '3'" > $MAST_ROOT/docker-compose.override.yml
  echo "services:" >> $MAST_ROOT/docker-compose.override.yml
fi

if [ -z "$_DB_HOST" ]; then
  echo "=== Configure dockerized database"
  export _PG_ADMIN_PASSWD="$(openssl rand -hex 32)"
  export _DB_HOST="db"
  export _DB_PORT="5432"
  export _DB_NAME="mastodon"
  export _DB_USER="mastodon"
  export _DB_PASS="$(openssl rand -hex 32)"
  docker run --pull never --name pgsetup -v $DATA_ROOT/postgres14:/var/lib/postgresql/data -e POSTGRES_PASSWORD=$_PG_ADMIN_PASSWD -d postgres:14-alpine
  docker exec pgsetup bash -c 'until pg_isready -U postgres; do sleep 1; done'
  docker exec pgsetup psql -U postgres -c "CREATE USER $_DB_USER WITH PASSWORD '$_DB_PASS' CREATEDB;"
  docker exec pgsetup psql -U postgres -c "CREATE DATABASE $_DB_NAME;"
  docker exec pgsetup psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE $_DB_NAME TO $_DB_USER";
  docker stop pgsetup
  docker rm -f pgsetup
else
  echo "=== Configure remote database"
  echo "  db:" >> $MAST_ROOT/docker-compose.override.yml
  echo "    image: tianon/true" >> $MAST_ROOT/docker-compose.override.yml
  echo "    restart: no" >> $MAST_ROOT/docker-compose.override.yml
fi

echo "=== App setup"
export _SECRET_KEY_BASE="$(openssl rand -hex 128)"
export _OTP_SECRET="$(openssl rand -hex 128)"

docker run --pull never --rm node:bookworm-slim npx web-push generate-vapid-keys > /tmp/vapidout
export _VAPID_PUBLIC_KEY="$(cat /tmp/vapidout |grep -A1 'Public Key'|grep -v 'Public Key')"
export _VAPID_PRIVATE_KEY="$(cat /tmp/vapidout |grep -A1 'Private Key'|grep -v 'Private Key')"
rm /tmp/vapidout

cat init/dotenv.production.tmpl | envsubst > $MAST_ROOT/.env.production

echo "=== Initialize database"
docker compose run -e RAILS_ENV=production web bundle exec rails db:schema:load db:seed
docker compose run -e RAILS_ENV=production web bundle exec rails runner "user = User.new(email: '$_ADMIN_EMAIL', password: '$_ADMIN_PASSWD', confirmed_at: Time.now.utc, account_attributes: { username: '$_ADMIN_USER' }, bypass_invite_request_check: true, role: UserRole.find_by(name: 'Owner')); user.save(validate: false); Setting.site_contact_username = '$_ADMIN_USER'"
docker compose run -e RAILS_ENV=production web bundle exec rails runner "user = User.new(email: '$_SVC_USER_EMAIL', password: '$_SVC_USER_PASSWD', confirmed_at: Time.now.utc, account_attributes: { username: '$_SVC_USER' }, bypass_invite_request_check: true, role: UserRole.find_by(name: 'Owner')); user.save(validate: false);"

if [ ! -z "$_RELAY_HOSTNAME" ]; then
  echo "=== Setup relay"
  mkdir $DATA_ROOT/relay

  openssl genrsa -traditional | sudo tee $DATA_ROOT/relay/actor.pem
  cat init/relay-config.yml.tmpl | envsubst '$_RELAY_HOSTNAME' > $DATA_ROOT/relay/config.yml
else
  echo "=== Skip relay"
  echo "  relay-server:" >> $MAST_ROOT/docker-compose.override.yml
  echo "    image: tianon/true" >> $MAST_ROOT/docker-compose.override.yml
  echo "    restart: no" >> $MAST_ROOT/docker-compose.override.yml
  echo "    command: /true" >> $MAST_ROOT/docker-compose.override.yml
  echo "  relay-redis:" >> $MAST_ROOT/docker-compose.override.yml
  echo "    image: tianon/true" >> $MAST_ROOT/docker-compose.override.yml
  echo "    restart: no" >> $MAST_ROOT/docker-compose.override.yml
  echo "    command: /true" >> $MAST_ROOT/docker-compose.override.yml
  echo "  relay-worker:" >> $MAST_ROOT/docker-compose.override.yml
  echo "    image: tianon/true" >> $MAST_ROOT/docker-compose.override.yml
  echo "    restart: no" >> $MAST_ROOT/docker-compose.override.yml
  echo "    command: /true" >> $MAST_ROOT/docker-compose.override.yml
fi

echo "=== nginx setup"
mkdir -p $DATA_ROOT/nginx/conf.d $DATA_ROOT/nginx/tmp $DATA_ROOT/nginx/certs $DATA_ROOT/nginx/lebase

echo "=== http setup for letsencrypt"
export _SERVER_HOSTNAME=$_APP_HOSTNAME
cat init/http-letsencrypt.conf.tmpl | envsubst '$_SERVER_HOSTNAME' > $DATA_ROOT/nginx/conf.d/http-letsencrypt-mast.conf
if [ ! -z "$_RELAY_HOSTNAME" ]; then
  export _SERVER_HOSTNAME=$_RELAY_HOSTNAME
  cat init/http-letsencrypt.conf.tmpl | envsubst '$_SERVER_HOSTNAME' > $DATA_ROOT/nginx/conf.d/http-letsencrypt-relay.conf
fi
unset _SERVER_HOSTNAME

docker run --pull never --name ngle \
  -v  ./data/nginx/tmp:/var/run/openresty \
  -v ./data/nginx/conf.d:/etc/nginx/conf.d \
  -v /etc/letsencrypt/:/etc/letsencrypt/ \
  -v ./data/nginx/lebase:/lebase \
  -p 80:80 \
  -d \
  openresty/openresty:bullseye

echo "=== SSL certificates"
certbot certonly -n --webroot -w $DATA_ROOT/nginx/lebase -d $_APP_HOSTNAME --rsa-key-size 4096 --agree-tos --email coursemanager@skytap.com

if [ ! -z "$_RELAY_HOSTNAME" ]; then
  certbot certonly -n --webroot -w $DATA_ROOT/nginx/lebase -d $_RELAY_HOSTNAME --rsa-key-size 4096 --agree-tos --email coursemanager@skytap.com
fi

echo "/usr/local/bin/certbot renew" | tee /etc/cron.daily/certbot-renew

docker stop ngle
docker rm -f ngle

echo "=== https setup for app"
cat init/https-mast.conf.tmpl | envsubst '$_APP_HOSTNAME' > $DATA_ROOT/nginx/conf.d/https-mast.conf
if [ ! -z "$_RELAY_HOSTNAME" ]; then
  cat init/https-relay.conf.tmpl | envsubst '$_RELAY_HOSTNAME' > $DATA_ROOT/nginx/conf.d/https-relay.conf
fi
unset _SERVER_HOSTNAME

echo "=== Add user to docker group"
usermod -aG docker user

echo "=== Start docker compose to create containers"
docker compose up -d

echo "=== Configure and start app service"
cat > /etc/systemd/system/mast_app.service <<EOF
[Unit]
Description=Mastodon app
After=docker.service
Requires=docker.service
Before=getty@tty1.service getty@tty2.service getty@tty3.service getty@tty4.service getty@tty5.service getty@tty6.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c "docker compose -f $MAST_ROOT/docker-compose.yml start"
ExecStop=/bin/bash -c "docker compose -f $MAST_ROOT/docker-compose.yml stop"

[Install]
WantedBy=multi-user.target
EOF

systemctl enable mast_app.service
service mast_app start

echo "=== Disable init script from running again"
touch $DONE_FILE

# Not currently using the systemd unit, so don't need to disable it
# systemctl disable mast_init.service

echo "=== Done!"