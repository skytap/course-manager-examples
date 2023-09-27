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

skytap_metadata = SkytapMetadata.get
lab_control = LabControl.get
control_data = lab_control.control_data
mastodon_admin_email = lab_control.control_data['user_identifier'].chomp(" (preview)")

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
skytap_pip_interface_hostname = lab_control.find_metadata_attr('skytap_pip_interface_hostname')
skytap_mastodon_server_template_id = lab_control.find_metadata_attr('skytap_mastodon_server_template_id')
lab_uuid = lab_control.find_metadata_attr('lab_uuid')

configuration_url = skytap_metadata.metadata['configuration_url']

unless lab_uuid
  lab_uuid = SecureRandom.uuid
  lab_control.update_control_data({ "metadata" => { "lab_uuid" => lab_uuid }})
end

skytap_client = SkytapClient.new(skytap_username, skytap_token)
original_skytap_environment = skytap_client.get(configuration_url)
originally_running = original_skytap_environment['vms'].any? {|vm| vm['runstate'] == 'running'}

puts "Adding Mastodon server to environment..."
skytap_environment = skytap_client.put(configuration_url, template_id: skytap_mastodon_server_template_id)
mastodon_server_vm_id =
  (skytap_environment['vms'].map {|vm| vm['id']} -
  original_skytap_environment['vms'].map {|vm| vm['id']}).first

if publish_set = skytap_environment['publish_sets'].first
  puts "Adding Mastodon server to sharing portal..."
  publish_set_vms = publish_set['vms'].map {|vm| vm.slice('vm_ref', 'access')}
  publish_set_vms << {
    vm_ref: "https://cloud.skytap.com/vms/#{mastodon_server_vm_id}",
    access: 'run_and_use'
  }
  skytap_client.put(publish_set['url'], vms: publish_set_vms)
end

if original_skytap_environment['runstate'] == 'running'
  puts "Starting Mastodon server..."
  skytap_client.put(
    configuration_url,
    runstate: 'running',
    multiselect: [mastodon_server_vm_id]
  )
end

puts "Refreshing lab in console..."
lab_control.refresh_lab

puts "Configuring lab public IP and DNS..."

interface = skytap_environment['vms']
              .detect {|vm| vm['id'] == mastodon_server_vm_id }['interfaces']
              .first

if interface
  pip = interface['public_ip_attachments'].detect { |ip| ip['connect_type'] == 'dynamic' }

  unless pip
    update_url = [configuration_url, 'vms', interface['vm_id'], 'interfaces', interface['id'], 'dynamic_public_ips.json'].join('/')
    pip = skytap_client.post(update_url, {}).first
  end

  lab_fqdn = pip['dns_name']

  lab_control.update_control_data({ "metadata" => { "lab_fqdn" => lab_fqdn, "mastodon_admin_email" => mastodon_admin_email }})
else
  puts 'Network interface not found in Skytap'
end

puts 'Provisioning course resources...'

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

puts 'Provisioning lab resources...'

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
      key: "#{ lab_uuid }.tfstate",
      use_azuread_auth: true
    },
    vars: {
      resource_group: resource_group,
      storage_account: storage_account,
      container: container,
      lab_uuid: lab_uuid,
      sendgrid_key: sendgrid_key
    }
  }
).apply(write_output: true)
