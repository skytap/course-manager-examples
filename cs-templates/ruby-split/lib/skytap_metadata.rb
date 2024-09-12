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

require "json"
require_relative "api_helper"

class SkytapMetadata
  def self.get
    # for backwards compatibility
    new
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

  def metadata_json
    @metadata_json ||=
      if metadata_proxy_url = ENV["SKYTAP_METADATA_PROXY_URL"]
        APIHelper.rest_call(metadata_proxy_url, "get")
      else
        File.read(
          File.join(File.dirname(__FILE__), "stub_data/metadata.json")
        )
      end
  end
end