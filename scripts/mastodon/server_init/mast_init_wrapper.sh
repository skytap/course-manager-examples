#!/bin/bash

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