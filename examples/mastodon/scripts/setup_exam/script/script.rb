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
require 'skytap_client'
require 'json'
require 'tooter'
require 'user_factory'
require 'httplog'

HttpLog.configure { |config| config.enabled = false }

skytap_metadata = SkytapMetadata.get
lab_control = LabControl.get
control_data = lab_control.control_data

if lab_control.find_metadata_attr('http_debug') == '1'
  HttpLog.configure { |config| config.enabled = true }
end

configuration_url = skytap_metadata.metadata['configuration_url']
skytap_username = lab_control.find_metadata_attr('skytap_username')
skytap_token = lab_control.find_metadata_attr('skytap_token')
skytap_client = SkytapClient.new(skytap_username, skytap_token)

mastodon_users = JSON.parse(lab_control.find_metadata_attr('mastodon_users'))

user_factory = UserFactory.new
bot_user = user_factory.create_user

mastodon_users['esbot'] = [bot_user]

lab_control.update_control_data('metadata' => {
  'mastodon_users' => mastodon_users.to_json,
  'troll_username' => bot_user['username']
})

tooter = Tooter.new(content_types: %w{ esbot })

5.times do
  tooter.toot
end
