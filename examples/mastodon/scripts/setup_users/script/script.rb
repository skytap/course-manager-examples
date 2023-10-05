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

require "lab_control"
require 'server_tools'
require 'json'
require 'tooter'
require 'user_factory'

lab_control = LabControl.get
control_data = lab_control.control_data

if mastodon_users = lab_control.find_metadata_attr('mastodon_users')
  mastodon_users = JSON.parse(mastodon_users)
else
  factory = UserFactory.new
  en_user = factory.create_user
  es_user = factory.create_user
  troll_user = factory.create_user

  mastodon_users = {
    'en' => [ en_user ],
    'es' => [ es_user ],
    'esbot' => [ troll_user ],
  }

  lab_control.update_control_data('metadata' => {
    'mastodon_users' => mastodon_users.to_json,
    'windows_user_email' => en_user['email'],
    'windows_user_password' => en_user['password'],
    'troll_username' => troll_user['username']
  })
end

tooter = Tooter.new(content_types: %w{ en es })

20.times do
  tooter.toot
end
