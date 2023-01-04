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

class LabControl
  def self.get
    @lab_control ||= new(SkytapMetadata.get.control_url)
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

  def initialize(control_url)
    @control_url = control_url
  end

  def lab_broadcast(type)
    broadcast_url = "#{control_data['user_access_url']}/learning_console/broadcast"
    APIHelper.rest_call(broadcast_url, "post", {type: type})
  end

  def control_data_json
    @control_data_json ||= APIHelper.rest_call(@control_url, "get")
  end
end