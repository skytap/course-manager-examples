# Copyright 2022 Skytap Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "sinatra/base"

class MetadataStubServer < Sinatra::Base
  set :lab_url, ENV['CM_LAB_URL'] || "http://gw/lab_access/self_learner/1/111"
  set :control_url, ENV['CM_CONTROL_URL'] || "#{settings.lab_url}/control/1/111"
  set :broadcast_url, ENV['CM_BROADCAST_URL'] || "#{settings.lab_url}/learning_console/broadcast"

  set :control_data_json, File.read(File.join(File.dirname(__FILE__), "control_data.json"))
  set :metadata_json, File.read(File.join(File.dirname(__FILE__), "metadata.json.erb"))

  before { content_type "application/json" }

  get '/skytap' do
    control_url = settings.control_url
    ERB.new(settings.metadata_json).result(binding)
  end

  get URI(settings.control_url).path do
    settings.control_data_json
  end

  put URI(settings.control_url).path do
    body = JSON.parse(request.body.read) rescue {}
    if integration_data = body["integration_data"]
      settings.control_data_json = JSON.parse(settings.control_data_json).tap do |h|
        h["integration_data"] = integration_data
      end.to_json
    end

    settings.control_data_json
  end

  post URI(settings.broadcast_url).path do
    "{}"
  end
end