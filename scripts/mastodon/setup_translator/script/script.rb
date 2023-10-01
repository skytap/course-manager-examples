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
require 'json'
require 'net/http'
require 'uri'
require 'securerandom'

uri = URI('https://eastus.api.cognitive.microsoft.com/sts/v1.0/issueToken')
lab_control = LabControl.get
translation_key = lab_control.find_metadata_attr('translation_key')
host = lab_control.find_metadata_attr('mastodon_server_ip')
user = lab_control.find_metadata_attr('mastodon_server_username')
password = lab_control.find_metadata_attr('mastodon_server_password')

unless translator_password = lab_control.find_metadata_attr('translator_password')
  translator_password = SecureRandom.hex(10)
  server_manager = MastodonServerManager.new(host, user, password)
  server_manager.setup_user(
    username: 'translator',
    email: 'translator@bot.fake',
    password: translator_password,
    display_name: 'Translator'
  )
  lab_control.update_control_data('metadata' => { 'translator_password' => translator_password })
end

req = Net::HTTP::Post.new(uri)
req['Ocp-Apim-Subscription-Key'] = translation_key

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

response = http.request(req)

case response
when Net::HTTPSuccess
  puts 'Token generated successfully'
else
  abort 'Error occurred during token generation'
  puts response.body
end

lab_control.update_control_data('metadata' => { 'translation_token' => response.body })
