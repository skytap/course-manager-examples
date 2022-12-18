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
require_relative "api_helper"

class SkytapMetadata
  METADATA_URL = "http://gw/skytap"

  def self.get
    @skytap_metadata ||= new(METADATA_URL)
  end

  def metadata
    JSON.parse(metadata_json)
  end

  def user_data
    JSON.parse(metadata["user_data"])
  end

  def configuration_user_data
    JSON.parse(metadata["configuration_user_data"])
  end

  def control_url
    user_data["control_url"]
  end

  private

  def initialize(metadata_url)
    @metadata_url = metadata_url
  end

  def metadata_json
    @metadata_json ||= APIHelper.rest_call(@metadata_url, "get")
  end
end