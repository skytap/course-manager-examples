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

require "json"
require_relative "skytap_metadata"
require_relative "api_helper"

class BaseLabControl
  def initialize(control_url)
    @control_url = control_url
  end

  def control_data
    JSON.parse(control_data_json)
  end

  def update_control_data(data)
    result_body = APIHelper.rest_call(@control_url, "put", data)
    @control_data_json = result_body
  end

  def refresh_content_pane
    lab_broadcast :refresh_content_pane
  end

  def refresh_lab
    lab_broadcast :refresh_lab
  end

  private

  def lab_broadcast(type)
    return unless lab_broadcast_url
    APIHelper.rest_call(lab_broadcast_url, "post", {type: type})
  end

  def control_data_json
    @control_data_json ||= APIHelper.rest_call(@control_url, "get")
  end

  def lab_broadcast_url
    "#{control_data['user_access_url']}/learning_console/broadcast"
  end
end

class StubbedLabControl < BaseLabControl
  def initialize; end

  def update_control_data(data)
    @control_data_json = JSON.parse(@control_data_json).merge(data.to_h).to_json
  rescue
    raise ArgumentError, "Invalid data"
  end

  private

  def lab_broadcast_url
    nil
  end

  def control_data_json
    @control_data_json ||= File.read(File.join(File.dirname(__FILE__), "stub_data/control_data_sample.json"))
  end
end

class LabControl
  def self.get
    @lab_control ||= 
      if SkytapMetadata.get.stubbed?
        StubbedLabControl.new
      else
        BaseLabControl.new(SkytapMetadata.get.control_url)
      end
  end
end