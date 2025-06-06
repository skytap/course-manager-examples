# Copyright 2025 Skytap Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "json"
require "faraday"

class LabControl
  def self.get
    @lab_control ||=
      if control_url = ENV["CONTROL_ENDPOINT_URL"]
        LiveLabControl.new(control_url, ENV["CREDENTIAL_USERNAME"], ENV["CREDENTIAL_TOKEN"])
      else
        StubbedLabControl.new
      end
  end

  def control_data
    @control_data ||= JSON.parse(control_data_json)
  end

  def update_control_data(data) = raise NotImplementedError

  def refresh_content_pane = raise NotImplementedError

  def refresh_lab = raise NotImplementedError

  def find_metadata_attr(key, within = nil)
    collections = within ? [within] : ['metadata', 'sensitive_metadata']
    collections.each do |collection|
      [nil, 'event', 'course', 'user', 'feature'].each do |obj|
        if this_level_value = control_data.dig(*[obj, collection, key].compact)
          return this_level_value
        end
      end
    end

    nil
  end

  private

  def control_data_json = raise NotImplementedError
end

class LiveLabControl < LabControl
  attr_reader :control_url, :username, :token, :connection

  def initialize(control_url, username, token)
    @control_url = control_url
    @username = username
    @token = token

    @connection = Faraday.new do |conn|
      conn.request :json
      conn.request :authorization, :basic, @username, @token if @username && @token
      conn.response :raise_error
      conn.adapter Faraday.default_adapter
    end
  end

  def update_control_data(data)
    response = @connection.put(@control_url, data)
    @control_data_json = response.body
  end

  def refresh_content_pane = lab_broadcast(:refresh_content_pane)

  def refresh_lab = lab_broadcast(:refresh_lab)

  private

  def lab_broadcast(type)
    broadcast_url = "#{control_data['user_access_url']}/learning_console/broadcast"
    @connection.post(broadcast_url, { type: type })
  end

  def control_data_json
    @control_data_json ||= @connection.get(@control_url).body
  end
end

class StubbedLabControl < LabControl
  def refresh_content_pane = nil

  def refresh_lab = nil

  def control_data_json
    @control_data_json ||= File.read(
      File.join(File.dirname(__FILE__), "stub_data/control_data.json")
    )
  end

  def update_control_data(data)
    METADATA_FIELDS.each do |keys|
      incoming_metadata = data.dig(*keys)
      update_metadata(keys, incoming_metadata) if incoming_metadata.is_a?(Hash)
    end
    control_data
  end

  METADATA_FIELDS = [
    ['metadata'], ['sensitive_metadata'],
    ['feature', 'metadata'], ['feature', 'sensitive_metadata'],
    ['course', 'metadata'], ['course', 'sensitive_metadata'],
    ['user', 'metadata'], ['user', 'sensitive_metadata'],
    ['event', 'metadata'], ['event', 'sensitive_metadata'],
  ].freeze
  private_constant :METADATA_FIELDS

  private

  def update_metadata(keys, incoming_metadata)
    control_data[keys.first] ||= {}
    if keys.length > 1
      control_data[keys.first][keys[1]] ||= {} if keys[1]
      control_data[keys.first][keys[1]].merge!(incoming_metadata).compact!
    else
      control_data[keys.first].merge!(incoming_metadata).compact!
    end
  end
end