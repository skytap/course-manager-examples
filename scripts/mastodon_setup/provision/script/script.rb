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

skytap_metadata = SkytapMetadata.get
lab_control = LabControl.get
control_data = lab_control.control_data

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

lab_uuid = lab_control.find_metadata_attr('lab_uuid')

configuration_url = skytap_metadata.metadata['configuration_url']

unless lab_uuid
  lab_uuid = SecureRandom.uuid
  lab_control.update_control_data({ "metadata" => { "lab_uuid" => lab_uuid }})
end

puts "Configuring lab public IP and DNS..."

skytap_client = SkytapClient.new(skytap_username, skytap_token)

skytap_environment = skytap_client.get(configuration_url)

interface = nil

skytap_environment['vms'].each do |vm|
  vm['interfaces'].each do |nic|
    if nic['hostname'] == skytap_pip_interface_hostname
      interface = nic
      break
    end
  end
end

raise "VM network interface not found with hostname: #{ skytap_pip_interface_hostname }" unless interface

pip = interface['public_ip_attachments'].detect { |ip| ip['connect_type'] == 'dynamic' }

unless pip
  update_url = [configuration_url, 'vms', interface['vm_id'], 'interfaces', interface['id'], 'dynamic_public_ips.json'].join('/')
  pip = skytap_client.post(update_url, {}).first
end

lab_fqdn = pip['dns_name']

lab_control.update_control_data({ "metadata" => { "lab_fqdn" => lab_fqdn }})

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
