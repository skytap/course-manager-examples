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
require 'http'
require 'faker'
require 'json'
require 'tooter'

skytap_metadata = SkytapMetadata.get
lab_control = LabControl.get
control_data = lab_control.control_data

mast_ip = lab_control.find_metadata_attr('mastodon_server_ip')
mast_fqdn = lab_control.find_metadata_attr('lab_fqdn')
mast_status_endpoint = "https://#{ mast_fqdn }/api/v1/statuses"

if mastodon_users = lab_control.find_metadata_attr('mastodon_users')
  mastodon_users = JSON.parse(mastodon_users)
else
  mast_manager = MastodonServerManager.new(mast_ip, 'user', 'Password1!')
  new_users = []

  6.times do 
    display_name = "#{ Faker::Name.first_name } #{ Faker::Name.last_name }"
    user_attributes = { 
      username: Faker::Internet.username(specifier: display_name, separators: ['_']),
      email: Faker::Internet.email(name: display_name),
      password: Faker::Internet.password(min_length: 10),
      display_name: display_name
    }

    user_token = mast_manager.setup_user_and_token(**user_attributes)
    new_users << { **user_attributes, 'token' => user_token }
  end

  mastodon_users = {}
  mastodon_users['esbot'] = [ new_users.shift ]
  mastodon_users['en'] = new_users.shift(3)
  mastodon_users['es'] = new_users

  lab_control.update_control_data('metadata' => { 'mastodon_users' => mastodon_users.to_json })
end

tooter = Tooter.new(content_types: %w{ en en es esbot })

20.times do
  tooter.toot
end
