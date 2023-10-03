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
require 'server_tools'
# require 'http'
# require 'faker'
require 'httplog'
# require 'json'
# require 'rest-client'

HttpLog.configure { |config| config.enabled = false }

skytap_metadata = SkytapMetadata.get
lab_control = LabControl.get
control_data = lab_control.control_data

if lab_control.find_metadata_attr('http_debug') == '1'
  HttpLog.configure { |config| config.enabled = true }
end

mast_ip = lab_control.find_metadata_attr('mastodon_server_ip')
mast_user = lab_control.find_metadata_attr('mastodon_server_username')
mast_pass = lab_control.find_metadata_attr('mastodon_server_password')
mast_fqdn = lab_control.find_metadata_attr('lab_fqdn')
mast_status_endpoint = "https://#{ mast_fqdn }/api/v1/statuses"
ssh_public_key = lab_control.find_metadata_attr('mastodon_ssh_public_key')
hosts_file = '/etc/hosts'

new_line = "#{mast_ip} #{mast_fqdn}\n"

unless File.read(hosts_file).include?(new_line)
  open(hosts_file, 'a') {|f| f.puts(new_line)}
end

mast_manager = MastodonServerManager.new(mast_ip, mast_user, mast_pass)

dest_dir = mast_manager.copy_directory_to_server('copy_to_server')

puts "Copied files to #{ dest_dir }"

init_command = <<~EOF
  INIT_DIR=/opt/mastodon/init
  sudo cp #{ dest_dir }/* $INIT_DIR/
  sudo chmod +x $INIT_DIR/mast_init.sh
  sudo chmod +x $INIT_DIR/mast_init_wrapper.sh
  sudo $INIT_DIR/mast_init.sh
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  echo "#{ ssh_public_key }" >> ~/.ssh/authorized_keys
  chmod 644 ~/.ssh/authorized_keys
EOF

output = mast_manager.run(init_command)

puts output