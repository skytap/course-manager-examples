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

HttpLog.configure { |config| config.enabled = false }

skytap_metadata = SkytapMetadata.get
lab_control = LabControl.get
control_data = lab_control.control_data

if lab_control.find_metadata_attr('http_debug') == '1'
  HttpLog.configure { |config| config.enabled = true }
end

mastodon_admin_email = lab_control.control_data['user_identifier'].chomp(" (preview)")
lab_control.update_control_data({ "metadata" => { "mastodon_admin_email" => mastodon_admin_email }})

subscription_id = lab_control.find_metadata_attr('azure_subscription_id')
tenant_id = lab_control.find_metadata_attr('azure_tenant_id')
client_id = lab_control.find_metadata_attr('azure_client_id')
client_secret = lab_control.find_metadata_attr('azure_client_secret')
storage_account = lab_control.find_metadata_attr('azure_storage_account')
container = lab_control.find_metadata_attr('azure_container')
resource_group = lab_control.find_metadata_attr('azure_resource_group')

sendgrid_key = lab_control.find_metadata_attr('sendgrid_key')
skytap_username = lab_control.find_metadata_attr('skytap_username')
skytap_token = lab_control.find_metadata_attr('skytap_token')
skytap_mastodon_server_template_id = lab_control.find_metadata_attr('skytap_mastodon_server_template_id')
lab_id = lab_control.find_metadata_attr('lab_id')
mastodon_server_ip = lab_control.find_metadata_attr('mastodon_server_ip')
lab_fqdn = lab_control.find_metadata_attr('lab_fqdn')
lab_hostname = lab_fqdn.split('.').first

configuration_url = skytap_metadata.metadata['configuration_url']

skytap_client = SkytapClient.new(skytap_username, skytap_token)
skytap_environment = skytap_client.get(configuration_url)
originally_running = skytap_environment['vms'].any? {|vm| vm['runstate'] == 'running'}

# Avoid re-adding the Mastodon server on repeated runs
mastodon_server_vm_id = nil

mastodon_server_vm = skytap_environment['vms'].detect {|vm| vm['name'].include?('Mastodon')}

if mastodon_server_vm
  mastodon_server_vm_id = mastodon_server_vm['id']
else
  puts "Adding Mastodon server to environment..."
  original_skytap_environment = skytap_environment
  skytap_environment = skytap_client.put(configuration_url, template_id: skytap_mastodon_server_template_id)
  mastodon_server_vm_id =
    (skytap_environment['vms'].map {|vm| vm['id']} -
    original_skytap_environment['vms'].map {|vm| vm['id']}).first

  skytap_client.wait_until_not_busy(configuration_url)
end

puts "Updating LAN IP address..."
interface = skytap_environment['vms']
              .detect {|vm| vm['id'] == mastodon_server_vm_id }['interfaces']
              .first
interface_url = [configuration_url, 'vms', interface['vm_id'], 'interfaces', interface['id']].join('/')

# This will fail if we did it in a previous attempt and started the VM, so check first
if skytap_client.get(interface_url)['ip'] != mastodon_server_ip
  skytap_client.put(interface_url, {'ip' => mastodon_server_ip})
end

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

# If the lab was already running, run the Mastodon server too
if originally_running
  puts "Starting Mastodon server..."
  skytap_client.put(
    configuration_url,
    runstate: 'running',
    multiselect: [ mastodon_server_vm_id ]
  )

  skytap_client.wait_until_not_busy(configuration_url)
end

# The Mastodon server should now be visible in sharing portal, so refresh
puts "Refreshing lab in console..."
lab_control.refresh_lab

# Assumes there is a single network interface with a single dynamic public IP attached
puts "Updating hostname for public IP..."
pip = interface['public_ip_attachments'].detect { |ip| ip['connect_type'] == 'dynamic' }
pip_key = pip['public_ip_attachment_key']
pip_url = [configuration_url, 'vms', interface['vm_id'], 'interfaces', interface['id'], 'dynamic_public_ips', pip_key].join('/')
skytap_client.put(pip_url, hostname: lab_hostname)

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
      key: "#{ lab_id }.tfstate",
      use_azuread_auth: true
    },
    vars: {
      resource_group: resource_group,
      storage_account: storage_account,
      container: container,
      lab_id: lab_id,
      sendgrid_key: sendgrid_key
    }
  }
).apply(write_output: true)
