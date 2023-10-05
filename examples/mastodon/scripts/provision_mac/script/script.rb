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

require "skytap_metadata"
require "lab_control"
require 'aws-sdk-ec2'
require 'httplog'
require 'net/ssh'
require 'net/scp'

HttpLog.configure { |config| config.enabled = false }

skytap_metadata = SkytapMetadata.get
lab_control = LabControl.get

if lab_control.find_metadata_attr('http_debug') == '1'
  HttpLog.configure { |config| config.enabled = true }
end

# AWS creds
ENV['AWS_ACCESS_KEY_ID'] = lab_control.find_metadata_attr('aws_access_key_id')
ENV['AWS_SECRET_ACCESS_KEY'] = lab_control.find_metadata_attr('aws_secret_access_key')
ENV['AWS_DEFAULT_REGION'] = lab_control.find_metadata_attr('aws_default_region')

# Creds to log into the Mac AMI
MAC_USER = lab_control.find_metadata_attr('mac_user')
SSH_KEY_NAME = lab_control.find_metadata_attr('mac_ssh_key_name')
SSH_PRIV_KEY = lab_control.find_metadata_attr('mac_ssh_priv_key')

# The virtual browser's public key. This is the key we want the Mac to let us use to authenticate. I think we're already writing this?
SSH_AUTHORIZED_KEYS_ENTRY = lab_control.find_metadata_attr('mastodon_ssh_public_key')

NEW_MAC_PASS = lab_control.find_metadata_attr('mac_new_pass')
OLD_MAC_PASS = lab_control.find_metadata_attr('mac_old_pass')
VNC_PASSWORD = lab_control.find_metadata_attr('mac_vnc_password')

INSTANCE_TYPE = lab_control.find_metadata_attr('mac_instance_type')
ZONE = lab_control.find_metadata_attr('mac_zone')
AMI = lab_control.find_metadata_attr('mac_ami')
SECURITY_GROUP_ID = lab_control.find_metadata_attr('mac_security_group_id')

NUM_ALLOWED_HOSTS = lab_control.find_metadata_attr('mac_num_allowed_hosts').to_i

dns_name = lab_control.find_metadata_attr('mac_dns_name')

client = Aws::EC2::Client.new

unless dns_name
  available_hosts =
    client.describe_hosts(
      filter: [
        {name: 'instance-type', values: [INSTANCE_TYPE]},
        {name: 'state', values: ['available']}
      ]
    ).hosts.select { |h|
      h.available_capacity.available_instance_capacity.detect { |aic|
        aic.instance_type == INSTANCE_TYPE
      }.available_capacity > 0
    }
    
  host_id = available_hosts.first&.host_id

  unless host_id
    num_existing_hosts = client.describe_hosts(
      filter: [
        {name: 'instance-type', values: [INSTANCE_TYPE]},
      ]
    ).hosts.count

    if num_existing_hosts >= NUM_ALLOWED_HOSTS
      abort "We're sorry, but all the Macs are in use right now. Please try again later."
    end

    host_id = client.allocate_hosts(
      auto_placement: 'on',
      availability_zone: ZONE,
      instance_type: INSTANCE_TYPE,
      quantity: 1
    ).host_ids[0]

    # puts "Created new host"
  end

  # puts "Using host id: #{host_id}"

  instance_id = client.run_instances(
    image_id: AMI,
    instance_type: INSTANCE_TYPE,
    key_name: SSH_KEY_NAME,
    placement: {host_id: host_id},
    security_group_ids: [SECURITY_GROUP_ID],
    max_count: 1,
    min_count: 1
  ).instances.first.instance_id

  # puts "Created instance id: #{instance_id}"

  client.wait_until(:instance_running, instance_ids:[instance_id])

  instance = client.describe_instances(instance_ids: [instance_id])

  dns_name = instance.reservations.first.instances.first.network_interfaces.first.association.public_dns_name

  lab_control.update_control_data({'metadata' => {'mac_host_id' => host_id, 'mac_instance_id' => instance_id, 'mac_dns_name' => dns_name}})
end

# puts "DNS name: #{dns_name}"

# Need to wait until listening on port 22
retries = 1
max_retries = 50
sleep_interval = 10
begin
  # puts "Waiting for server, attempt #{retries} of #{max_retries}"
  Socket.tcp(dns_name, 22, connect_timeout: 1) {}
  
  # puts "Server seems up, testing SSH"
  Net::SSH.start(dns_name, 'ec2-user', key_data: [SSH_PRIV_KEY], non_interactive: true) do |ssh|
    ssh.exec! "echo SSH is working"
  end
rescue => ex
  # puts "Server is not ready: #{ex}"
  if retries <= max_retries
    sleep sleep_interval
    retries += 1
    retry
  else
    abort "Setting up the Mac timed out."
  end
end

mac_setup_script = <<~EOF
  #!/bin/bash
  echo "#{SSH_AUTHORIZED_KEYS_ENTRY}" >> ~/.ssh/authorized_keys
  sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -clientopts -setvnclegacy -vnclegacy yes -clientopts -setvncpw -vncpw #{VNC_PASSWORD} -restart -agent -privs -all
  sysadminctl -newPassword '#{NEW_MAC_PASS}' -oldPassword '#{OLD_MAC_PASS}'
  curl --output sengi.dmg -LO https://github.com/NicolasConstant/sengi-electron/releases/download/v1.8.0/Sengi-1.8.0-mac.dmg
  sudo hdiutil attach sengi.dmg
  sudo cp -R '/Volumes/Sengi 1.8.0/Sengi.app' /Applications
  curl --output displayplacer -LO https://github.com/jakehilborn/displayplacer/releases/download/v1.4.0/displayplacer-intel-v140
  sudo mv displayplacer /usr/local/bin
  sudo chmod 755 /usr/local/bin/displayplacer
  sudo hdiutil unmount '/Volumes/Sengi 1.8.0'
  EOF

login_script_config = <<~EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
   <key>Label</key>
   <string>com.user.loginscript</string>
   <key>ProgramArguments</key>
   <array><string>/Users/#{MAC_USER}/login.sh</string></array>
   <key>RunAtLoad</key>
   <true/>
</dict>
</plist>
EOF

login_script = <<~EOF
#!/bin/bash
/usr/local/bin/displayplacer 'id:69784AF1-CD7D-B79B-E5D4-60D937407F68 res:1440x900 hz:60 color_depth:8 enabled:true scaling:off origin:(0,0) degree:0'
hdiutil unmount '/Volumes/Sengi 1.8.0' || true
EOF

Net::SSH.start(dns_name, MAC_USER, key_data: [SSH_PRIV_KEY], non_interactive: true) do |ssh|
  output = ssh.exec!("mkdir -p /Users/#{MAC_USER}/Library/LaunchAgents")
  # puts output
  ssh.scp.upload! StringIO.new(login_script_config), "/Users/#{MAC_USER}/Library/LaunchAgents/LoginScripts.MacLoginScript.plist"

  ssh.scp.upload! StringIO.new(login_script), "/Users/#{MAC_USER}/login.sh"
  output = ssh.exec!("chmod +x /Users/#{MAC_USER}/login.sh")
  #puts output

  ssh.scp.upload! StringIO.new(mac_setup_script), "/tmp/mac_setup.sh"
  output = ssh.exec!("chmod +x /tmp/mac_setup.sh && /tmp/mac_setup.sh")
  #puts output
end

puts "The Mac has been provisioned successfully."