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
require "terraform_helper"
require "skytap_client"
require "uri"
require "httplog"
require "faker"
require "sshkey"

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
base_dns_name = lab_control.find_metadata_attr('base_dns_name')

configuration_url = skytap_metadata.metadata['configuration_url']

unless subdomain = lab_control.find_metadata_attr('lab_id')
  subdomain = "#{Faker::Adjective.positive}#{Faker::Name.first_name}#{rand(1..100000)}"[0..31].downcase
end

unless fqdn = lab_control.find_metadata_attr('lab_fqdn')
  fqdn = "#{subdomain}.#{base_dns_name}"
end

puts "Updating metadata with FQDN..."
lab_control.update_control_data(
  'metadata' => {
    'lab_id' => subdomain,
    'lab_fqdn' => fqdn,
    'mastodon_admin_email' => mastodon_admin_email
  }
)

unless priv_key = lab_control.find_metadata_attr('virtual_browser_ssh_key')
  key = SSHKey.generate
  pub_key = key.ssh_public_key
  priv_key = key.private_key

  puts "Updating metadata with SSH key and FQDN..."
  lab_control.update_control_data(
    'metadata' => {
      'mastodon_ssh_public_key' => pub_key,
      'virtual_browser_ssh_key' => priv_key,
    },
    'sensitive_metadata' => {
      'mastodon_ssh_private_key' => priv_key
    }
  )
end

skytap_mastodon_server_template_id = lab_control.find_metadata_attr('skytap_mastodon_server_template_id')
mastodon_server_ip = lab_control.find_metadata_attr('mastodon_server_ip')

configuration_url = skytap_metadata.metadata['configuration_url']
skytap_client = SkytapClient.new(skytap_username, skytap_token)
skytap_environment = skytap_client.get(configuration_url)

mastodon_server_vm_id = nil
mastodon_server_vm = skytap_environment['vms'].detect {|vm| vm['name'].include?('Mastodon')}

if mastodon_server_vm
  mastodon_server_vm_id = mastodon_server_vm['id']
else
  puts "Adding Mastodon server to environment..."
  original_skytap_environment = skytap_environment
  skytap_environment = skytap_client.put(configuration_url, template_id: skytap_mastodon_server_template_id)
  mastodon_server_vm_id = skytap_environment['vms'].detect {|vm| vm['name'].include?('Mastodon')}['id']
  skytap_client.wait_until_not_busy(configuration_url)

  # Assumes there is a single sharing portal (the CM-provisioned one)
  puts "Adding Mastodon server to sharing portal..."
  publish_set = skytap_environment['publish_sets'].first
  publish_set_vms = publish_set['vms'].map {|vm| vm.slice('vm_ref', 'access')}
  publish_set_vms << {
    vm_ref: "https://cloud.skytap.com/vms/#{mastodon_server_vm_id}",
    access: 'run_and_use'
  }
  skytap_client.put(publish_set['url'], vms: publish_set_vms)
end

skytap_environment = skytap_client.get(configuration_url)

mastodon_server_vm = skytap_environment['vms'].detect {|vm| vm['name'].include?('Mastodon')}
mastodon_server_vm_id = mastodon_server_vm['id']
mastodon_server_interface = skytap_environment['vms']
  .detect {|vm| vm['id'] == mastodon_server_vm_id }['interfaces']
  .first

mastodon_server_ip = mastodon_server_interface['ip']

skytap_client.wait_until_not_busy(configuration_url)

# Assumes there is a single network interface with a single dynamic public IP attached
puts "Updating hostname for public IP..."
pip = mastodon_server_interface['public_ip_attachments'].detect { |ip| ip['connect_type'] == 'dynamic' }
pip_key = pip['public_ip_attachment_key']
pip_url = [configuration_url, 'vms', mastodon_server_interface['vm_id'], 'interfaces', mastodon_server_interface['id'], 'dynamic_public_ips', pip_key].join('/')
skytap_client.put(pip_url, hostname: subdomain)

puts "Updating Virtual Browser hosts file..."
skytap_client.wait_until_not_busy(configuration_url)

virtual_browser_vm_id = skytap_environment['vms'].detect {|vm| vm['name'].include?('Virtual Browser')}['id']

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


# Assumes there is a single network interface with a single dynamic public IP attached
puts "Updating hostname for public IP..."
pip = mastodon_server_interface['public_ip_attachments'].detect { |ip| ip['connect_type'] == 'dynamic' }
pip_key = pip['public_ip_attachment_key']
pip_url = [configuration_url, 'vms', mastodon_server_interface['vm_id'], 'interfaces', mastodon_server_interface['id'], 'dynamic_public_ips', pip_key].join('/')
skytap_client.put(pip_url, hostname: subdomain)

# Removing sequence from environment
puts "Configuring all VMs to start..."
skytap_client.wait_until_not_busy(configuration_url)

vm_ids = skytap_environment['vms'].map { |vm| vm['id'] }

skytap_client.put([configuration_url, 'stages', '3'].join('/'), {
  'stage' => {
    'delay_after_finish_seconds' => 0,
    'vm_ids' => vm_ids
  }
})

puts "Updating metadata..."
lab_control.update_control_data('metadata' => { 'mastodon_server_ip' => mastodon_server_ip })

# The Mastodon server should now be visible in sharing portal, so refresh
puts "Refreshing lab in console..."
lab_control.refresh_lab

puts "Starting environment..."
lab_control.update_control_data(runstate: "running") 

subscription_id = lab_control.find_metadata_attr('azure_subscription_id')
tenant_id = lab_control.find_metadata_attr('azure_tenant_id')
client_id = lab_control.find_metadata_attr('azure_client_id')
client_secret = lab_control.find_metadata_attr('azure_client_secret')
storage_account = lab_control.find_metadata_attr('azure_storage_account')
container = lab_control.find_metadata_attr('azure_container')
resource_group = lab_control.find_metadata_attr('azure_resource_group')

sendgrid_key = lab_control.find_metadata_attr('sendgrid_key')
# skytap_mastodon_server_template_id = lab_control.find_metadata_attr('skytap_mastodon_server_template_id')
# The Mastodon server should now be visible in sharing portal, so refresh
# puts "Refreshing lab in console..."
# lab_control.refresh_lab


# puts "Starting environment..."
# lab_control.update_control_data(runstate: "running") 

puts "Provisioning course resources..."
TerraformHelper.new(
  dir: '/script/terraform/course',
  output_attribute: 'tf_course_provision_output',
  env: {
    ARM_SUBSCRIPTION_ID: subscription_id,
    ARM_TENANT_ID: tenant_id,
    ARM_CLIENT_ID: client_id,
    ARM_CLIENT_SECRET: client_secret
  },
  opts: {
    backend_config: {
      storage_account_name: storage_account,
      container_name: container,
      resource_group_name: resource_group,
      key: 'shared.tfstate',
      use_azuread_auth: true
    },
    vars: {
      resource_group: resource_group
    }
  }
).apply

puts "Provisioning lab resources..."
TerraformHelper.new(
  dir: '/script/terraform/lab',
  output_attribute: 'tf_lab_provision_output',
  env: {
    ARM_SUBSCRIPTION_ID: subscription_id,
    ARM_TENANT_ID: tenant_id,
    ARM_CLIENT_ID: client_id,
    ARM_CLIENT_SECRET: client_secret
  },
  opts: {
    backend_config: {
      storage_account_name: storage_account,
      container_name: container,
      resource_group_name: resource_group,
      key: "#{ subdomain }.tfstate",
      use_azuread_auth: true
    },
    vars: {
      resource_group: resource_group,
      storage_account: storage_account,
      container: container,
      lab_id: subdomain,
      sendgrid_key: sendgrid_key
    }
  }
).apply(write_output: true)

lab_control.refresh_content_pane

puts "Wait until not environment is ready..."
skytap_client.wait_until_not_busy(configuration_url)
