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

require "sinatra/base"

class MetadataStubServer < Sinatra::Base
  set :lab_url, ENV['CM_LAB_URL'] || "http://skytap-metadata/lab_access/self_learner/1/111"
  set :control_url, ENV['CM_CONTROL_URL'] || "#{settings.lab_url}/control/1/111"
  set :broadcast_url, ENV['CM_BROADCAST_URL'] || "#{settings.lab_url}/learning_console/broadcast"

  set :control_data_json, File.read(File.join(File.dirname(__FILE__), "lib/stub_data/control_data.json"))
  set :metadata_json, File.read(File.join(File.dirname(__FILE__), "lib/stub_data/metadata.json.erb"))

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
    control_data = JSON.parse(settings.control_data_json) rescue {}
    settings.control_data_json = control_data_merge(control_data, body).to_json
  end

  post URI(settings.broadcast_url).path do
    "{}"
  end

  private

  METADATA_FIELDS = [
    ['metadata'], ['sensitive_metadata'],
    ['feature', 'metadata'], ['feature', 'sensitive_metadata'],
    ['course', 'metadata'], ['course', 'sensitive_metadata'],
    ['user', 'metadata'], ['user', 'sensitive_metadata'],
    ['event', 'metadata'], ['event', 'sensitive_metadata'],
  ].freeze

  # Merges the incoming metadata into the Control Data.
  # @param control_data [Hash] The current Control Data.
  # @param body [Hash] The body of the request, from which we will pull the metadata.
  # @return [Hash] The Control Data with the updated metadata
  def control_data_merge(control_data, body)
    METADATA_FIELDS.each do |keys|
      incoming_metadata = body.dig(*keys)
      update_metadata(control_data, keys, incoming_metadata) if incoming_metadata.is_a? Hash
    end
    control_data
  end

  def update_metadata(control_data, keys, incoming_metadata)
    control_data[keys.first] ||= {}
    if keys.length > 1
      control_data[keys.first][keys[1]] ||= {} if keys[1]
      control_data[keys.first][keys[1]].merge!(incoming_metadata).compact!
    else
      control_data[keys.first].merge!(incoming_metadata).compact!
    end
  end
end
