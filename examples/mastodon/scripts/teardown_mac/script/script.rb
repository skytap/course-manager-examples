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

instance_id = lab_control.find_metadata_attr('mac_instance_id')
host_id = lab_control.find_metadata_attr('mac_host_id')

client = Aws::EC2::Client.new

client.terminate_instances(instance_ids: [instance_id])
#client.release_hosts(host_ids: [host_id])

puts "The Mac will begin its teardown process shortly."