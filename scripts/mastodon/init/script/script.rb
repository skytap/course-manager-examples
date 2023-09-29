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
require "skytap_client"
require "uri"
require "faker"
require "sshkey"
require "httplog"

HttpLog.configure { |config| config.enabled = false }

skytap_metadata = SkytapMetadata.get
lab_control = LabControl.get
control_data = lab_control.control_data

if lab_control.find_metadata_attr('http_debug') == '1'
  HttpLog.configure { |config| config.enabled = true }
end

mastodon_admin_email = lab_control.control_data['user_identifier'].chomp(" (preview)")
skytap_username = lab_control.find_metadata_attr('skytap_username')
skytap_token = lab_control.find_metadata_attr('skytap_token')
mastodon_server_ip = lab_control.find_metadata_attr('mastodon_server_ip')
base_dns_name = lab_control.find_metadata_attr('base_dns_name')

configuration_url = skytap_metadata.metadata['configuration_url']

subdomain = "#{Faker::Adjective.positive}#{Faker::Name.first_name}#{rand(1..100000)}"[0..31].downcase
fqdn = "#{subdomain}.#{base_dns_name}"

key = SSHKey.generate
pub_key = key.ssh_public_key
priv_key = key.private_key

puts "Updating metadata with SSH key and FQDN..."
lab_control.update_control_data(
  'metadata' => {
    'lab_id' => subdomain,
    'lab_fqdn' => fqdn,
    'mastodon_ssh_public_key' => pub_key,
    'virtual_browser_ssh_key' => priv_key
  },
  'sensitive_metadata' => {
     'mastodon_ssh_private_key' => priv_key
  }
)

# Assumes the Virtual Browser is actually in the lab
puts "Updating Virtual Browser hosts file..."

skytap_client = SkytapClient.new(skytap_username, skytap_token)

config = skytap_client.get(configuration_url)
virtual_browser_vm_id = config['vms'].detect {|vm| vm['name'].include?('Virtual Browser')}['id']
hosts_file_text = <<~EOF
  127.0.0.1       localhost
  127.0.1.1       kiosk
  169.254.169.254 skytap-metadata
  ::1     ip6-localhost ip6-loopback
  fe00::0 ip6-localnet
  ff00::0 ip6-mcastprefix
  ff02::1 ip6-allnodes
  ff02::2 ip6-allrouters
  #{mastodon_server_ip} #{fqdn}
  EOF

skytap_client.put(
  "https://cloud.skytap.com/vms/#{virtual_browser_vm_id}/user_data",
  contents: {
    'files' => [
      {
        'path' => '/etc/hosts',
        'text' => hosts_file_text,
        'overwrite' => true
      }
    ]
  }.to_json
)